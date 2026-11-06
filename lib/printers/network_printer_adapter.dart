import 'dart:io';
import 'dart:async';

import '../models/printer_device.dart';
import '../core/constants/app_constants.dart';
import 'printer_adapter.dart';

class NetworkPrinterAdapter implements PrinterAdapter {
  @override
  final PrinterDevice device;

  Socket? _socket;
  bool _connected = false;

  NetworkPrinterAdapter(this.device);

  @override
  Future<bool> connect() async {
    final ip = device.ipAddress;
    final port = device.port;

    if (ip == null || ip.trim().isEmpty) {
      throw Exception('Printer IP address is required.');
    }

    try {
      await disconnect(); // Clean previous connection if open
      _socket = await Socket.connect(
        ip.trim(),
        port,
        timeout: AppConstants.socketTimeout,
      );

      _connected = true;
      device.isConnected = true;
      device.lastConnected = DateTime.now();
      device.lastError = null;
      return true;
    } on SocketException catch (e) {
      _connected = false;
      device.isConnected = false;
      final msg = 'Unable to connect to ${ip.trim()}:$port (${e.message})';
      device.lastError = msg;
      throw Exception(msg);
    } on TimeoutException {
      _connected = false;
      device.isConnected = false;
      final msg = 'Connection to ${ip.trim()}:$port timed out.';
      device.lastError = msg;
      throw Exception(msg);
    } catch (e) {
      _connected = false;
      device.isConnected = false;
      final msg = 'Network printer error: ${e.toString()}';
      device.lastError = msg;
      throw Exception(msg);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _socket?.flush();
      await _socket?.close();
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    _connected = false;
    device.isConnected = false;
  }

  @override
  Future<bool> isConnected() async {
    return _connected && _socket != null;
  }

  @override
  Future<void> sendRawBytes(List<int> bytes) async {
    if (!_connected || _socket == null) {
      await connect();
    }

    try {
      _socket!.add(bytes);
      await _socket!.flush();
    } catch (e) {
      _connected = false;
      device.isConnected = false;
      final msg = 'Failed sending bytes to network printer: ${e.toString()}';
      device.lastError = msg;
      throw Exception(msg);
    }
  }
}
