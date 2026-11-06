import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';

import '../models/printer_device.dart';
import 'printer_adapter.dart';

class BluetoothPrinterAdapter implements PrinterAdapter {
  @override
  final PrinterDevice device;

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  bool _connected = false;

  BluetoothPrinterAdapter(this.device);

  @override
  Future<bool> connect() async {
    final mac = device.macAddress;
    if (mac == null || mac.isEmpty) {
      throw Exception('Bluetooth MAC address is required.');
    }

    try {
      final bool? isConnectedAlready = await _bluetooth.isConnected;
      if (isConnectedAlready == true) {
        _connected = true;
        device.isConnected = true;
        device.lastConnected = DateTime.now();
        device.lastError = null;
        return true;
      }

      // Create BluetoothDevice instance from mac and name
      BluetoothDevice bluetoothDevice = BluetoothDevice(device.name, mac);

      final bool? result = await _bluetooth.connect(bluetoothDevice);
      if (result == true) {
        _connected = true;
        device.isConnected = true;
        device.lastConnected = DateTime.now();
        device.lastError = null;
        return true;
      } else {
        _connected = false;
        device.isConnected = false;
        final msg =
            'Failed to connect to Bluetooth printer ${device.name} ($mac).';
        device.lastError = msg;
        throw Exception(msg);
      }
    } catch (e) {
      _connected = false;
      device.isConnected = false;
      final msg = e.toString().contains('permission')
          ? 'Bluetooth permission required.'
          : 'Bluetooth printer disconnected/unavailable: ${e.toString()}';
      device.lastError = msg;
      throw Exception(msg);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
    } catch (_) {}
    _connected = false;
    device.isConnected = false;
  }

  @override
  Future<bool> isConnected() async {
    try {
      final bool? state = await _bluetooth.isConnected;
      _connected = state == true;
      device.isConnected = _connected;
      return _connected;
    } catch (_) {
      _connected = false;
      device.isConnected = false;
      return false;
    }
  }

  @override
  Future<void> sendRawBytes(List<int> bytes) async {
    final bool connected = await isConnected();
    if (!connected) {
      await connect();
    }

    try {
      final Uint8List uint8list = Uint8List.fromList(bytes);
      await _bluetooth.writeBytes(uint8list);
    } catch (e) {
      _connected = false;
      device.isConnected = false;
      final msg = 'Bluetooth print write failed: ${e.toString()}';
      device.lastError = msg;
      throw Exception(msg);
    }
  }
}
