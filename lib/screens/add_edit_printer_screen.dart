import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../models/printer_device.dart';
import '../services/storage_service.dart';
import '../printers/printer_adapter.dart';
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

  bool _isTesting = false;
  String? _testMessage;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final p = widget.printerToEdit;

    _name = p?.name ?? '';
    _connectionType = p?.connectionType ?? ConnectionType.bluetooth;
    _paperWidth = p?.paperWidth ?? PaperWidth.mm80;
    _role = p?.role ?? PrinterRole.bill;

    _macAddress = p?.macAddress;
    _vendorId = p?.vendorId;
    _productId = p?.productId;
    _usbDeviceName = p?.deviceName;

    _ipAddress = p?.ipAddress ?? '192.168.1.12';
    _port = p?.port ?? 9100;

    _scanBluetoothDevices();
    _scanUsbDevices();
  }

  Future<void> _scanBluetoothDevices() async {
    setState(() => _isScanningBt = true);
    try {
      final bt = BlueThermalPrinter.instance;
      final devices = await bt.getBondedDevices();
      if (mounted) {
        setState(() {
          _bluetoothDevices = devices;
          _isScanningBt = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isScanningBt = false);
    }
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
    final String id = widget.printerToEdit?.id ??
        'PRINTER-${DateTime.now().millisecondsSinceEpoch}';

    return PrinterDevice(
      id: id,
      name: _name.trim().isEmpty ? '${_role.label} (${_connectionType.name.toUpperCase()})' : _name.trim(),
      connectionType: _connectionType,
      paperWidth: _paperWidth,
      role: _role,
      macAddress: _macAddress,
      vendorId: _vendorId,
      productId: _productId,
      deviceName: _usbDeviceName,
      ipAddress: _ipAddress.trim(),
      port: _port,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.printerToEdit == null ? 'Add Printer' : 'Edit Printer'),
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
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: 'Printer Name',
                  hintText: 'e.g. Kitchen LAN Printer',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.print_rounded),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter printer name' : null,
                onSaved: (val) => _name = val ?? '',
              ),
              const SizedBox(height: 16),

              // Connection Type Selector
              const Text('Connection Method:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r.label),
                        );
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
              const Text('Connection Details:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),

              if (_connectionType == ConnectionType.bluetooth) ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _macAddress,
                        decoration: const InputDecoration(
                          labelText: 'Paired Bluetooth Printer',
                          border: OutlineInputBorder(),
                        ),
                        items: _bluetoothDevices.map((d) {
                          return DropdownMenuItem(
                            value: d.address,
                            child: Text('${d.name ?? "BT Device"} (${d.address})'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _macAddress = val),
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
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _macAddress,
                  decoration: const InputDecoration(
                    labelText: 'Or enter MAC Address manually',
                    hintText: '00:11:22:33:44:55',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => _macAddress = val.trim(),
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
                          final String devName = d['deviceName'] as String? ?? 'USB Printer';
                          final int vid = d['vendorId'] as int? ?? 0;
                          final int pid = d['productId'] as int? ?? 0;
                          return DropdownMenuItem<String>(
                            value: devName,
                            child: Text('$devName (VID:$vid PID:$pid)'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          final dev =
                              _usbDevices.firstWhere((d) => d['deviceName'] == val);
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
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Enter IP address' : null,
                  onSaved: (val) => _ipAddress = val ?? '192.168.1.12',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _port.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Port (Default: 9100)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || int.tryParse(val) == null ? 'Enter valid port' : null,
                  onSaved: (val) => _port = int.tryParse(val ?? '9100') ?? 9100,
                ),
              ],

              const SizedBox(height: 20),

              // Test Result Banner
              if (_testMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _testSuccess ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _testSuccess
                            ? Colors.green.shade300
                            : Colors.red.shade300),
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
