import 'package:flutter/services.dart';

import '../models/pos_order.dart';
import '../models/printer_device.dart';
import 'storage_service.dart';

/// Bridge to the native Kotlin print engine (Android text layout and
/// raster, calibration sheet).
class NativeEngineService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.thermalprinter/engine',
  );

  /// The printer's real settings, so native output uses the same width,
  /// characters per line and threshold as the Dart engine.
  static Map<String, dynamic> profileMap(PrinterDevice device) => {
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
    'printableDots': device.effectiveDots,
    'charsPerLine': device.effectiveCharsPerLine,
    'darknessPreset': 'EXTRA_DARK',
    'bitmapThreshold': device.rasterThreshold ?? 150,
  };

  /// Prints the native calibration sheet.
  static Future<bool> runCalibration(PrinterDevice device) async {
    try {
      final bool? result = await _channel.invokeMethod('runCalibration', {
        'profile': profileMap(device),
      });
      return result == true;
    } catch (e) {
      throw Exception('Calibration error: ${e.toString()}');
    }
  }

  /// Prints [order] with the native BillFormatter / KotFormatter, using the
  /// business details from the app's business profile.
  static Future<bool> printNativeOrder({
    required PosOrder order,
    required PrinterDevice device,
  }) async {
    try {
      final storage = await StorageService.getInstance();
      final business = await storage.businessProfile.get();
      final bool? result = await _channel.invokeMethod('printNativeOrder', {
        'profile': profileMap(device),
        'order': order.toJson(),
        'template': business.toJson(),
      });
      return result == true;
    } catch (e) {
      throw Exception('Native Print Error: ${e.toString()}');
    }
  }
}
