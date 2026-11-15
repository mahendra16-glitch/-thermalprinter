import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'bluetooth_permissions.dart';

/// Android Bluetooth major device classes (BluetoothClass.Device.Major).
class BtMajor {
  BtMajor._();
  static const misc = 0x0000;
  static const computer = 0x0100;
  static const phone = 0x0200;
  static const network = 0x0300;
  static const audioVideo = 0x0400;
  static const peripheral = 0x0500;
  static const imaging = 0x0600;
  static const wearable = 0x0700;
  static const toy = 0x0800;
  static const health = 0x0900;
  static const uncategorized = 0x1F00;

  /// Printers report "imaging", and many cheap ones "uncategorized" or
  /// nothing; phones, computers, audio, keyboards etc. are not printers.
  static bool maybePrinter(int major) =>
      major == imaging ||
      major == uncategorized ||
      major == misc ||
      major == -1;

  static String label(int major) => switch (major) {
    imaging => 'Printer',
    computer => 'Computer',
    phone => 'Phone',
    audioVideo => 'Audio',
    peripheral => 'Keyboard / mouse',
    wearable => 'Watch / wearable',
    network => 'Network',
    toy => 'Toy',
    health => 'Health device',
    _ => 'Unknown type',
  };
}

/// A Bluetooth device paired in Android settings.
class PairedBluetoothDevice {
  final String name;
  final String address;

  /// Android says it is a printer / imaging device. Many cheap printers
  /// report another class, so this only sorts the list.
  final bool looksLikePrinter;

  /// [BtMajor] class, -1 if unknown.
  final int major;

  const PairedBluetoothDevice(
    this.name,
    this.address,
    this.looksLikePrinter, [
    this.major = -1,
  ]);

  bool get maybePrinter => BtMajor.maybePrinter(major);
}

/// Lists paired devices through the app's own Android code, which needs
/// only the "Nearby devices" permission. (blue_thermal_printer's own
/// `getBondedDevices` also wants location on Android 12+ and never returns
/// if it has to ask for it.) Printers first, then by name.
///
/// Throws an [Exception] with a message for staff.
Future<List<PairedBluetoothDevice>> pairedBluetoothDevices({
  Duration timeout = const Duration(seconds: 10),
}) async {
  const channel = MethodChannel('com.example.thermalprinter/bluetooth');
  try {
    final raw = await channel
        .invokeListMethod<Map<dynamic, dynamic>>('getBondedDevices')
        .timeout(timeout);
    final list = [
      for (final m in raw ?? const <Map<dynamic, dynamic>>[])
        PairedBluetoothDevice(
          (m['name'] as String?) ?? '',
          m['address'] as String,
          m['printer'] == true,
          (m['major'] as int?) ?? -1,
        ),
    ];
    list.sort((a, b) {
      if (a.looksLikePrinter != b.looksLikePrinter) {
        return a.looksLikePrinter ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  } on TimeoutException {
    throw Exception(
      'Android did not answer in time. Turn Bluetooth off and on, then tap '
      'refresh.',
    );
  } on PlatformException catch (e) {
    throw Exception(switch (e.code) {
      'bt_off' => 'Bluetooth is turned off. Turn it on, then tap refresh.',
      'no_permission' =>
        'Allow "Nearby devices" for this app in Android Settings > Apps, '
            'then tap refresh.',
      'unsupported' => 'This device has no Bluetooth.',
      _ => 'Could not list paired devices: ${e.message ?? e.code}',
    });
  }
}

/// Turns a raw Bluetooth connect error into something staff can act on.
String friendlyBluetoothError(Object error, String mac) {
  final t = error.toString().toLowerCase();
  if (t.contains('permission')) {
    return 'Bluetooth permission required: allow "Nearby devices" for this '
        'app.';
  }
  if (t.contains('read failed') ||
      t.contains('socket might closed') ||
      t.contains('timeout') ||
      t.contains('connect_error')) {
    return 'Could not connect to the printer ($mac). Check that it is '
        'switched on and close to this device, that it is paired in Android '
        'Bluetooth settings, and that no other phone or tablet is connected '
        'to it. Then try again.';
  }
  if (t.contains('bluetooth') && t.contains('off')) {
    return 'Bluetooth is turned off. Turn it on and try again.';
  }
  return 'Bluetooth printer unavailable ($mac): '
      '${error.toString().replaceAll('Exception: ', '').split('\n').first}';
}

/// A device found by [scanNearbyBluetooth].
class NearbyBluetoothDevice {
  final String name;
  final String address;
  final int major;
  final bool paired;

  /// Signal strength in dBm (higher is closer), if Android gave one.
  final int? rssi;

  /// False for Bluetooth Low Energy-only devices, which this app cannot
  /// print to over Bluetooth.
  final bool classic;

  const NearbyBluetoothDevice({
    required this.name,
    required this.address,
    required this.major,
    required this.paired,
    required this.rssi,
    required this.classic,
  });

  bool get maybePrinter => classic && BtMajor.maybePrinter(major);

  /// 1 (weak) to 4 (strong), 0 if unknown.
  int get bars {
    final r = rssi;
    if (r == null) return 0;
    if (r >= -60) return 4;
    if (r >= -70) return 3;
    if (r >= -80) return 2;
    return 1;
  }

  static NearbyBluetoothDevice fromMap(Map<dynamic, dynamic> m) =>
      NearbyBluetoothDevice(
        name: (m['name'] as String?) ?? '',
        address: m['address'] as String,
        major: (m['major'] as int?) ?? -1,
        paired: m['bonded'] == true,
        rssi: m['rssi'] as int?,
        classic: m['classic'] != false,
      );
}

/// One search event: a device, or the end of the search (null device).
typedef BluetoothScanEvent = NearbyBluetoothDevice?;

String _scanError(String code) => switch (code) {
  'bt_off' => 'Bluetooth is turned off. Turn it on and search again.',
  'no_permission' =>
    'Allow "Nearby devices" for this app in Android Settings > Apps, then '
        'search again.',
  'need_location' =>
    'This Android version needs location permission (and location turned '
        'on) to search for Bluetooth devices.',
  'unsupported' => 'This device has no Bluetooth.',
  'scan_failed' =>
    'Android did not start the search. Turn Bluetooth off and on, then try '
        'again.',
  _ => 'The search failed ($code).',
};

/// Searches for nearby Bluetooth devices for about 12 seconds (Android's
/// limit). Emits each device as it is found, then null when the search
/// ends. Errors carry a message for staff.
Stream<BluetoothScanEvent> scanNearbyBluetooth() async* {
  final problem = await ensureBluetoothPermissions();
  if (problem != null) throw Exception(problem);
  const channel = EventChannel('com.example.thermalprinter/bluetooth_scan');
  for (var attempt = 0; attempt < 2; attempt++) {
    try {
      await for (final e in channel.receiveBroadcastStream()) {
        final m = e as Map<dynamic, dynamic>;
        if (m['event'] == 'finished') {
          yield null;
          return;
        }
        yield NearbyBluetoothDevice.fromMap(m);
      }
      return;
    } on PlatformException catch (e) {
      // Android 11 and older need location for Bluetooth searches (newer
      // versions don't: the scan permission is "never for location").
      if (e.code == 'need_location' && attempt == 0 && Platform.isAndroid) {
        final st = await Permission.locationWhenInUse.request();
        if (st.isGranted) continue;
      }
      throw Exception(_scanError(e.code));
    }
  }
}

/// Pairs with [address]. Android shows its own pairing prompt (some
/// printers ask for a PIN such as 0000 or 1234). Returns true when paired.
Future<bool> pairBluetoothDevice(String address) async {
  const channel = MethodChannel('com.example.thermalprinter/bluetooth');
  try {
    final ok = await channel
        .invokeMethod<bool>('pair', {'address': address})
        .timeout(const Duration(seconds: 90));
    return ok == true;
  } on TimeoutException {
    throw Exception('Pairing took too long. Try again next to the printer.');
  } on PlatformException catch (e) {
    throw Exception(
      e.code == 'pair_failed'
          ? 'Android could not start pairing. Switch the printer off and on, '
                'then try again.'
          : _scanError(e.code),
    );
  }
}
