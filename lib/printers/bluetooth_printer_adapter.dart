import 'dart:io';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as bt;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;

import '../models/printer_device.dart';
import 'bluetooth_permissions.dart';
import 'paired_bluetooth.dart';
import 'printer_adapter.dart';

/// Bluetooth Printer Adapter supporting:
/// - Android: Bluetooth Classic SPP (`blue_thermal_printer`)
/// - iOS (iPhone): Bluetooth Low Energy BLE (`flutter_blue_plus`)
class BluetoothPrinterAdapter implements PrinterAdapter {
  @override
  final PrinterDevice device;

  final bt.BlueThermalPrinter _bluetoothAndroid = bt.BlueThermalPrinter.instance;
  ble.BluetoothDevice? _bleDeviceIOS;

  static String? _connectedMac;

  BluetoothPrinterAdapter(this.device);

  String get _mac => (device.macAddress ?? '').toUpperCase();

  @override
  Future<bool> connect() async {
    if (_mac.isEmpty) {
      throw Exception('Bluetooth MAC / Remote Identifier is required.');
    }

    if (Platform.isIOS) {
      return _connectIOSBLE();
    } else {
      return _connectAndroidClassic();
    }
  }

  Future<bool> _connectAndroidClassic() async {
    final permissionProblem = await ensureBluetoothPermissions();
    if (permissionProblem != null) {
      device.lastError = permissionProblem;
      throw Exception(permissionProblem);
    }

    try {
      final connectedNow = await _bluetoothAndroid.isConnected == true;
      if (connectedNow && _connectedMac == _mac) {
        _markConnected();
        return true;
      }
      if (connectedNow) {
        try {
          await _bluetoothAndroid.disconnect();
        } catch (_) {}
        _connectedMac = null;
      }

      final result = await _bluetoothAndroid.connect(
        bt.BluetoothDevice(device.name, device.macAddress),
      );
      if (result == true) {
        _connectedMac = _mac;
        _markConnected();
        return true;
      }
      throw Exception(
        'Failed to connect to Bluetooth printer ${device.name} '
        '(${device.macAddress}). Is it powered on?',
      );
    } catch (e) {
      _connectedMac = null;
      device.isConnected = false;
      final msg = friendlyBluetoothError(e, _mac);
      device.lastError = msg;
      throw Exception(msg);
    }
  }

  Future<bool> _connectIOSBLE() async {
    try {
      final String targetId = device.macAddress ?? '';
      if (targetId.isEmpty) {
        throw Exception('Bluetooth Remote Identifier / UUID is required.');
      }

      // 1. Wait for CoreBluetooth adapter state to settle (prevents CBManagerStateUnknown)
      try {
        if (ble.FlutterBluePlus.adapterStateNow != ble.BluetoothAdapterState.on) {
          await ble.FlutterBluePlus.adapterState
              .where((state) => state == ble.BluetoothAdapterState.on)
              .first
              .timeout(const Duration(seconds: 3));
        }
      } catch (_) {}

      // 2. Connect using FlutterBluePlus
      final bluetoothDevice = ble.BluetoothDevice.fromId(targetId);
      await bluetoothDevice.connect(timeout: const Duration(seconds: 8));
      _bleDeviceIOS = bluetoothDevice;
      _connectedMac = _mac;
      _markConnected();
      return true;
    } catch (e) {
      device.isConnected = false;
      final msg = 'iOS BLE Printer Connection Error: ${e.toString()}';
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
      if (Platform.isIOS && _bleDeviceIOS != null) {
        await _bleDeviceIOS!.disconnect();
        _bleDeviceIOS = null;
      } else {
        await _bluetoothAndroid.disconnect();
      }
    } catch (_) {}
    _connectedMac = null;
    device.isConnected = false;
  }

  @override
  Future<bool> isConnected() async {
    try {
      if (Platform.isIOS && _bleDeviceIOS != null) {
        final state = await _bleDeviceIOS!.connectionState.first;
        final isConn = state == ble.BluetoothConnectionState.connected;
        device.isConnected = isConn;
        return isConn;
      } else {
        final state = await _bluetoothAndroid.isConnected == true;
        final mine = state && _connectedMac == _mac;
        device.isConnected = mine;
        return mine;
      }
    } catch (_) {
      device.isConnected = false;
      return false;
    }
  }

  @override
  Future<void> sendRawBytes(List<int> bytes) async {
    if (!await isConnected()) await connect();

    try {
      if (Platform.isIOS && _bleDeviceIOS != null) {
        final services = await _bleDeviceIOS!.discoverServices();
        ble.BluetoothCharacteristic? writeCharacteristic;

        for (var service in services) {
          for (var char in service.characteristics) {
            if (char.properties.write || char.properties.writeWithoutResponse) {
              writeCharacteristic = char;
              break;
            }
          }
          if (writeCharacteristic != null) break;
        }

        if (writeCharacteristic == null) {
          throw Exception('No writable BLE characteristic found on thermal printer.');
        }

        // Chunk data into 100-byte BLE MTU blocks
        final chunkSize = 100;
        for (int i = 0; i < bytes.length; i += chunkSize) {
          final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
          final chunk = bytes.sublist(i, end);
          await writeCharacteristic.write(
            chunk,
            withoutResponse: writeCharacteristic.properties.writeWithoutResponse,
          );
        }
      } else {
        await _bluetoothAndroid.writeBytes(Uint8List.fromList(bytes));
      }
    } catch (e) {
      _connectedMac = null;
      device.isConnected = false;
      final msg = 'Bluetooth print write failed: ${e.toString()}';
      device.lastError = msg;
      throw Exception(msg);
    }
  }
}
