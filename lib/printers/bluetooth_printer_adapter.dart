import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';

import '../models/printer_device.dart';
import 'bluetooth_permissions.dart';
import 'printer_adapter.dart';

/// Bluetooth Classic (SPP) printer via the blue_thermal_printer plugin.
///
/// The plugin keeps a single connection for the whole app and cannot say
/// *which* device it is connected to, so this adapter remembers the MAC it
/// connected to. If a job is for a different printer, the old connection is
/// closed first; otherwise a KOT could go to the bill printer (D12).
class BluetoothPrinterAdapter implements PrinterAdapter {
  @override
  final PrinterDevice device;

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  /// MAC of the printer the shared plugin connection belongs to.
  static String? _connectedMac;

  BluetoothPrinterAdapter(this.device);

  String get _mac => (device.macAddress ?? '').toUpperCase();

  @override
  Future<bool> connect() async {
    if (_mac.isEmpty) {
      throw Exception('Bluetooth MAC address is required.');
    }
    final permissionProblem = await ensureBluetoothPermissions();
    if (permissionProblem != null) {
      device.lastError = permissionProblem;
      throw Exception(permissionProblem);
    }

    try {
      final connectedNow = await _bluetooth.isConnected == true;
      if (connectedNow && _connectedMac == _mac) {
        _markConnected();
        return true;
      }
      if (connectedNow) {
        // Connected to another printer: release it first.
        try {
          await _bluetooth.disconnect();
        } catch (_) {}
        _connectedMac = null;
      }

      final result = await _bluetooth.connect(
        BluetoothDevice(device.name, device.macAddress),
      );
      if (result == true) {
        _connectedMac = _mac;
        _markConnected();
        return true;
      }
      throw Exception(
        'Failed to connect to Bluetooth printer ${device.name} '
        '(${device.macAddress}). Is it on and paired?',
      );
    } catch (e) {
      _connectedMac = null;
      device.isConnected = false;
      final msg = e.toString().toLowerCase().contains('permission')
          ? 'Bluetooth permission required.'
          : 'Bluetooth printer unavailable: ${e.toString().replaceAll('Exception: ', '')}';
      device.lastError = msg;
      throw Exception(msg);
    }
  }

  void _markConnected() {
    device.isConnected = true;
    device.lastConnected = DateTime.now();
    device.lastError = null;
  }

  @override
  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
    } catch (_) {}
    _connectedMac = null;
    device.isConnected = false;
  }

  @override
  Future<bool> isConnected() async {
    try {
      final state = await _bluetooth.isConnected == true;
      final mine = state && _connectedMac == _mac;
      device.isConnected = mine;
      return mine;
    } catch (_) {
      device.isConnected = false;
      return false;
    }
  }

  @override
  Future<void> sendRawBytes(List<int> bytes) async {
    if (!await isConnected()) await connect();
    try {
      await _bluetooth.writeBytes(Uint8List.fromList(bytes));
    } catch (e) {
      _connectedMac = null;
      device.isConnected = false;
      final msg = 'Bluetooth print write failed: ${e.toString()}';
      device.lastError = msg;
      throw Exception(msg);
    }
  }
}
