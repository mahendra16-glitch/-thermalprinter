import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../models/printer_device.dart';
import 'printer_adapter.dart';

class UsbPrinterAdapter implements PrinterAdapter {
  @override
  final PrinterDevice device;

  static const MethodChannel _channel =
      MethodChannel('com.example.thermalprinter/usb');
  bool _connected = false;

  UsbPrinterAdapter(this.device);

  static Future<List<Map<String, dynamic>>> getConnectedUsbDevices() async {
    try {
      final List<dynamic>? list =
          await _channel.invokeMethod('getUsbDevices');
      if (list == null) return [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> connect() async {
    try {
      final bool? result = await _channel.invokeMethod('connectUsb', {
        'vendorId': device.vendorId,
        'productId': device.productId,
        'deviceName': device.deviceName,
      });

      if (result == true) {
        _connected = true;
        device.isConnected = true;
        device.lastConnected = DateTime.now();
        device.lastError = null;
        return true;
      } else {
        _connected = false;
        device.isConnected = false;
        final msg = 'Failed connecting to USB printer ${device.name}.';
        device.lastError = msg;
        throw Exception(msg);
      }
    } on PlatformException catch (e) {
      _connected = false;
      device.isConnected = false;
      final msg = e.code == 'PERMISSION_REQUIRED'
          ? 'USB permission required. Please allow on phone prompt.'
          : 'USB Printer Error: ${e.message}';
      device.lastError = msg;
      throw Exception(msg);
    } catch (e) {
      _connected = false;
      device.isConnected = false;
      final msg = 'USB Error: ${e.toString()}';
      device.lastError = msg;
      throw Exception(msg);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnectUsb');
    } catch (_) {}
    _connected = false;
    device.isConnected = false;
  }

  @override
  Future<bool> isConnected() async {
    return _connected;
  }

  @override
  Future<void> sendRawBytes(List<int> bytes) async {
    if (!_connected) {
      await connect();
    }

    try {
      final Uint8List data = Uint8List.fromList(bytes);
      await _channel.invokeMethod('sendRawBytes', {'bytes': data});
    } catch (e) {
      _connected = false;
      device.isConnected = false;
      final msg = 'USB write failed: ${e.toString()}';
      device.lastError = msg;
      throw Exception(msg);
    }
  }
}
