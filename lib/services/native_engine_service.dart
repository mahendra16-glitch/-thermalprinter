import 'package:flutter/services.dart';

import '../models/printer_device.dart';
import '../models/pos_order.dart';

class NativeEngineService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.thermalprinter/engine',
  );

  /// Invokes native Kotlin CalibrationWizard to print a physical print calibration sheet
  static Future<bool> runCalibration(PrinterDevice device) async {
    try {
      final Map<String, dynamic> profileMap = {
        'id': device.id,
        'name': device.name,
        'connectionType': device.connectionType.name,
        'macAddress': device.macAddress,
        'vendorId': device.vendorId,
        'productId': device.productId,
        'deviceName': device.deviceName,
        'ipAddress': device.ipAddress,
        'port': device.port,
        'paperWidth': device.paperWidth.name,
        'darknessPreset': 'EXTRA_DARK',
        'bitmapThreshold': 150,
      };

      final bool? result = await _channel.invokeMethod('runCalibration', {
        'profile': profileMap,
      });

      return result == true;
    } catch (e) {
      throw Exception('Calibration error: ${e.toString()}');
    }
  }

  /// Invokes native Kotlin PrinterManager with ThermalRasterEngine & BillFormatter/KotFormatter
  static Future<bool> printNativeOrder({
    required PosOrder order,
    required PrinterDevice device,
  }) async {
    try {
      final Map<String, dynamic> profileMap = {
        'id': device.id,
        'name': device.name,
        'connectionType': device.connectionType.name,
        'macAddress': device.macAddress,
        'vendorId': device.vendorId,
        'productId': device.productId,
        'deviceName': device.deviceName,
        'ipAddress': device.ipAddress,
        'port': device.port,
        'paperWidth': device.paperWidth.name,
        'darknessPreset': 'EXTRA_DARK',
        'bitmapThreshold': 150,
      };

      final bool? result = await _channel.invokeMethod('printNativeOrder', {
        'profile': profileMap,
        'order': order.toJson(),
      });

      return result == true;
    } catch (e) {
      throw Exception('Native Print Error: ${e.toString()}');
    }
  }
}
