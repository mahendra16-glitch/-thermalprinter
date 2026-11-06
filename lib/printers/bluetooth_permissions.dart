import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Asks for the Bluetooth permissions Android 12+ requires ("Nearby
/// devices"). Returns null when allowed, otherwise a message for staff.
/// On older Android versions these permissions are granted at install.
Future<String?> ensureBluetoothPermissions() async {
  if (!Platform.isAndroid) return null;
  final results = await [
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
  ].request();
  final connect = results[Permission.bluetoothConnect];
  if (connect == null || connect.isGranted || connect.isLimited) return null;
  if (connect.isPermanentlyDenied) {
    return 'Bluetooth permission is blocked. Open Android Settings > Apps > '
        'this app > Permissions and allow "Nearby devices".';
  }
  return 'Bluetooth permission was not given. Allow "Nearby devices" to use '
      'Bluetooth printers.';
}
