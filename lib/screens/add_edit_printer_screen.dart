import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

import '../models/printer_device.dart';
import '../services/storage_service.dart';
import '../printers/printer_adapter.dart';
import '../printers/bluetooth_permissions.dart';
import '../printers/paired_bluetooth.dart';
import 'nearby_printers_screen.dart';
import '../printers/usb_printer_adapter.dart';
import '../widgets/test_print_dialog.dart';

class AddEditPrinterScreen extends StatefulWidget {
  final PrinterDevice? printerToEdit;

  const AddEditPrinterScreen({super.key, this.printerToEdit});

  @override
  State<AddEditPrinterScreen> createState() => _AddEditPrinterScreenState();
}

class _AddEditPrinterScreenState extends State<AddEditPrinterScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late ConnectionType _connectionType;
  late PaperWidth _paperWidth;
  late PrinterRole _role;

  // Bluetooth fields
  String? _macAddress;
  final _macCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  /// Device class of each paired device (address -> [BtMajor]).
  Map<String, int> _pairedMajor = {};
  bool _showAllPaired = false;
  List<BluetoothDevice> _bluetoothDevices = [];
  bool _isScanningBt = false;

  // USB fields
  int? _vendorId;
  int? _productId;
  String? _usbDeviceName;
  List<Map<String, dynamic>> _usbDevices = [];
  bool _isScanningUsb = false;

  // Network fields
  late String _ipAddress;
  late int _port;

  // Advanced print settings (empty = default for the paper width).
  final _dots = TextEditingController();
  final _chars = TextEditingController();
  final _threshold = TextEditingController();
  final _feed = TextEditingController();
  bool _autoCut = true;

  bool _isTesting = false;
  String? _testMessage;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final p = widget.printerToEdit;

    _name = p?.name ?? '';
    _nameCtrl.text = _name;
    _connectionType = p?.connectionType ?? ConnectionType.bluetooth;
    _paperWidth = p?.paperWidth ?? PaperWidth.mm80;
    _role = p?.role ?? PrinterRole.bill;

    _macAddress = p?.macAddress;
    _macCtrl.text = p?.macAddress ?? '';
    _vendorId = p?.vendorId;
    _productId = p?.productId;
    _usbDeviceName = p?.deviceName;

    _ipAddress = p?.ipAddress ?? '';
    _dots.text = p?.printableDots?.toString() ?? '';
    _chars.text = p?.charsPerLine?.toString() ?? '';
    _threshold.text = p?.rasterThreshold?.toString() ?? '';
    _feed.text = p?.feedLines?.toString() ?? '';
    _autoCut = p?.autoCut ?? true;
    _port = p?.port ?? 9100;

    _scanBluetoothDevices();
    _scanUsbDevices();
  }

  @override
  void dispose() {
    for (final c in [_macCtrl, _nameCtrl, _dots, _chars, _threshold, _feed]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _btProblem;

  Future<void> _scanBluetoothDevices() async {
    setState(() {
      _isScanningBt = true;
      _btProblem = null;
    });
    try {
      final problem = await ensureBluetoothPermissions();
      if (problem != null) {
        if (mounted) {
          setState(() {
            _btProblem = problem;
            _isScanningBt = false;
          });
        }
        return;
      }
      final paired = await pairedBluetoothDevices();
      final devices = [
        for (final d in paired)
          BluetoothDevice(d.name.isEmpty ? null : d.name, d.address),
      ];
      _pairedMajor = {for (final d in paired) d.address: d.major};
      if (mounted) {
        setState(() {
          _bluetoothDevices = devices;
          _isScanningBt = false;
          if (devices.isEmpty) {
            _btProblem =
                'No paired Bluetooth devices yet. Tap "Find nearby printers" '
                'to search and pair one.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanningBt = false;
          _btProblem = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  /// Paired devices that may be printers (phones, headphones, computers
  /// hidden unless asked for). The saved printer is always kept.
  List<BluetoothDevice> _visiblePaired() {
    if (_showAllPaired) return _bluetoothDevices;
    return _bluetoothDevices
        .where(
          (d) =>
              d.address == _macAddress ||
              BtMajor.maybePrinter(_pairedMajor[d.address] ?? -1),
        )
        .toList();
  }

  int _printerPairedCount() => _bluetoothDevices
      .where((d) => BtMajor.maybePrinter(_pairedMajor[d.address] ?? -1))
      .length;

  Future<void> _findNearby() async {
    final picked = await Navigator.of(context).push<NearbyBluetoothDevice>(
      MaterialPageRoute(builder: (_) => const NearbyPrintersScreen()),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _macAddress = picked.address;
      _macCtrl.text = picked.address;
      if (_nameCtrl.text.trim().isEmpty && picked.name.isNotEmpty) {
        _nameCtrl.text = picked.name;
      }
    });
    await _scanBluetoothDevices();
  }

  Future<void> _scanUsbDevices() async {
    setState(() => _isScanningUsb = true);
    try {
      final devices = await UsbPrinterAdapter.getConnectedUsbDevices();
      if (mounted) {
        setState(() {
          _usbDevices = devices;
          _isScanningUsb = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isScanningUsb = false);
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = false;
    });

    final tempDevice = _buildPrinterDevice();
    final adapter = PrinterAdapter.forDevice(tempDevice);

    try {
      final success = await adapter.connect();
      await adapter.disconnect();

      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = success;
          _testMessage = success
              ? 'Successfully connected to printer!'
              : 'Connection failed.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  PrinterDevice _buildPrinterDevice() {
    final String id =
        widget.printerToEdit?.id ??
        'PRINTER-${DateTime.now().millisecondsSinceEpoch}';

    return PrinterDevice(
      id: id,
      name: _name.trim().isEmpty
          ? '${_role.label} (${_connectionType.name.toUpperCase()})'
          : _name.trim(),
      connectionType: _connectionType,
      paperWidth: _paperWidth,
      role: _role,
      macAddress: _macAddress,
      vendorId: _vendorId,
      productId: _productId,
      deviceName: _usbDeviceName,
      ipAddress: _ipAddress.trim(),
      port: _port,
      printableDots: int.tryParse(_dots.text.trim()),
      charsPerLine: int.tryParse(_chars.text.trim()),
      rasterThreshold: int.tryParse(_threshold.text.trim()),
      feedLines: int.tryParse(_feed.text.trim()),
      autoCut: _autoCut,
    );
  }

  Future<void> _savePrinter() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final printer = _buildPrinterDevice();
    final storage = await StorageService.getInstance();
    await storage.savePrinter(printer);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Widget _numberField(
    TextEditingController c,
    String label,
    String help, {
    required int min,
    required int max,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          helperText: help,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          if ((v ?? '').trim().isEmpty) return null;
          final n = int.tryParse(v!.trim());
          return (n == null || n < min || n > max)
              ? 'Enter $min to $max, or leave empty'
              : null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.printerToEdit == null ? 'Add Printer' : 'Edit Printer',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Printer Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Printer Name',
                  hintText: 'e.g. Kitchen LAN Printer',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.print_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter printer name'
                    : null,
                onSaved: (val) => _name = val ?? '',
              ),
              const SizedBox(height: 16),

              // Connection Type Selector
              const Text(
                'Connection Method:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ConnectionType>(
                segments: const [
                  ButtonSegment(
                    value: ConnectionType.bluetooth,
                    label: Text('Bluetooth'),
                    icon: Icon(Icons.bluetooth),
                  ),
                  ButtonSegment(
                    value: ConnectionType.usb,
                    label: Text('USB'),
                    icon: Icon(Icons.usb),
                  ),
                  ButtonSegment(
                    value: ConnectionType.network,
                    label: Text('Wi-Fi / LAN'),
                    icon: Icon(Icons.wifi),
                  ),
                ],
                selected: {_connectionType},
                onSelectionChanged: (set) {
                  setState(() {
                    _connectionType = set.first;
                    _testMessage = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Role & Width Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<PrinterRole>(
                      value: _role,
                      decoration: const InputDecoration(
                        labelText: 'Printer Role',
                        border: OutlineInputBorder(),
                      ),
                      items: PrinterRole.values.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r.label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _role = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<PaperWidth>(
                      value: _paperWidth,
                      decoration: const InputDecoration(
                        labelText: 'Paper Width',
                        border: OutlineInputBorder(),
                      ),
                      items: PaperWidth.values.map((w) {
                        return DropdownMenuItem(
                          value: w,
                          child: Text('${w.label} (${w.charsPerLine} cols)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _paperWidth = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Dynamic Connection Parameters
              const Text(
                'Connection Details:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),

              if (_connectionType == ConnectionType.bluetooth) ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        // Rebuilt when the list loads or the MAC is typed.
                        key: ValueKey(
                          '${_bluetoothDevices.length}-$_macAddress',
                        ),
                        isExpanded: true,
                        // A saved MAC that is not currently paired must not be
                        // passed as the value (the dropdown would throw).
                        initialValue:
                            _visiblePaired().any(
                              (d) => d.address == _macAddress,
                            )
                            ? _macAddress
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Paired Bluetooth Printer',
                          border: OutlineInputBorder(),
                        ),
                        items: _visiblePaired().map((d) {
                          return DropdownMenuItem(
                            value: d.address,
                            child: Text(
                              '${d.name ?? "BT Device"} (${d.address})',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() {
                          _macAddress = val;
                          _macCtrl.text = val ?? '';
                        }),
                      ),
                    ),
                    IconButton(
                      icon: _isScanningBt
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      onPressed: _scanBluetoothDevices,
                    ),
                  ],
                ),
                if (_bluetoothDevices.length > _visiblePaired().length ||
                    _showAllPaired)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      'Show all paired devices '
                      '(${_bluetoothDevices.length - _printerPairedCount()} '
                      'phones, headphones… hidden)',
                    ),
                    value: _showAllPaired,
                    onChanged: (v) =>
                        setState(() => _showAllPaired = v ?? false),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Find nearby printers'),
                    onPressed: _findNearby,
                  ),
                ),
                if (_btProblem != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _btProblem!,
                      style: const TextStyle(color: Color(0xFFB45309)),
                    ),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _macCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Or enter MAC Address manually',
                    hintText: '00:11:22:33:44:55',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => _macAddress = val.trim().toUpperCase(),
                ),
              ] else if (_connectionType == ConnectionType.usb) ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _usbDeviceName,
                        decoration: const InputDecoration(
                          labelText: 'Detected USB Thermal Printer',
                          border: OutlineInputBorder(),
                        ),
                        items: _usbDevices.map((d) {
                          final String devName =
                              d['deviceName'] as String? ?? 'USB Printer';
                          final int vid = d['vendorId'] as int? ?? 0;
                          final int pid = d['productId'] as int? ?? 0;
                          return DropdownMenuItem<String>(
                            value: devName,
                            child: Text('$devName (VID:$vid PID:$pid)'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          final dev = _usbDevices.firstWhere(
                            (d) => d['deviceName'] == val,
                          );
                          setState(() {
                            _usbDeviceName = dev['deviceName'] as String?;
                            _vendorId = dev['vendorId'] as int?;
                            _productId = dev['productId'] as int?;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: _isScanningUsb
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      onPressed: _scanUsbDevices,
                    ),
                  ],
                ),
              ] else if (_connectionType == ConnectionType.network) ...[
                TextFormField(
                  initialValue: _ipAddress,
                  decoration: const InputDecoration(
                    labelText: 'Printer IP Address',
                    hintText: '192.168.1.12',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lan_rounded),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Enter IP address'
                      : null,
                  onSaved: (val) => _ipAddress = (val ?? '').trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _port.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Port (Default: 9100)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || int.tryParse(val) == null
                      ? 'Enter valid port'
                      : null,
                  onSaved: (val) => _port = int.tryParse(val ?? '9100') ?? 9100,
                ),
              ],

              const SizedBox(height: 12),
              ExpansionTile(
                // Keep the fields built while collapsed so the form still
                // validates them.
                maintainState: true,
                tilePadding: EdgeInsets.zero,
                title: const Text(
                  'Print settings (advanced)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Width ${_paperWidth.dots} dots, ${_paperWidth.charsPerLine} '
                  'characters unless changed here',
                  style: const TextStyle(fontSize: 12),
                ),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [
                  _numberField(
                    _dots,
                    'Printable width (dots)',
                    'Default ${_paperWidth.dots}. Some 80mm printers use 512.',
                    min: 200,
                    max: 832,
                  ),
                  _numberField(
                    _chars,
                    'Characters per line',
                    'Default ${_paperWidth.charsPerLine}. Try 42 if lines wrap.',
                    min: 16,
                    max: 64,
                  ),
                  _numberField(
                    _threshold,
                    'Image darkness threshold',
                    'Default 160. Higher = darker images and Hindi text.',
                    min: 80,
                    max: 220,
                  ),
                  _numberField(
                    _feed,
                    'Blank lines before cut',
                    'Default 3.',
                    min: 0,
                    max: 10,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cut paper after each print'),
                    subtitle: const Text(
                      'Turn off for printers without a cutter.',
                    ),
                    value: _autoCut,
                    onChanged: (v) => setState(() => _autoCut = v),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Test Result Banner
              if (_testMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _testSuccess
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _testSuccess
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testSuccess
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: _testSuccess ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testMessage!,
                          style: TextStyle(
                            color: _testSuccess ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: const Text('Test Connection'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          showDialog(
                            context: context,
                            builder: (ctx) =>
                                TestPrintDialog(device: _buildPrinterDevice()),
                          );
                        }
                      },
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Test Print'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _savePrinter,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Printer Configuration'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
