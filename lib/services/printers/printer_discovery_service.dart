import 'dart:async';
import 'dart:io';
import '../../models/printer_device.dart';

class DiscoveredPrinter {
  final String name;
  final ConnectionType connectionType;
  final String identifier; // IP for network, MAC for BT, VID/PID for USB
  final int port;

  DiscoveredPrinter({
    required this.name,
    required this.connectionType,
    required this.identifier,
    this.port = 9100,
  });
}

class PrinterDiscoveryService {
  /// Scans local network subnet (Port 9100) for active thermal printers
  static Future<List<DiscoveredPrinter>> discoverLocalNetworkPrinters({
    String? subnetPrefix,
    int port = 9100,
    Duration timeout = const Duration(milliseconds: 300),
  }) async {
    final List<DiscoveredPrinter> found = [];

    // Determine local subnet if not provided
    String prefix = subnetPrefix ?? '192.168.1';
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.contains('.')) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
              break;
            }
          }
        }
      }
    } catch (_) {}

    final List<Future<void>> tasks = [];

    for (int i = 1; i <= 254; i++) {
      final ip = '$prefix.$i';
      tasks.add(_testPort(ip, port, timeout).then((isOpen) {
        if (isOpen) {
          found.add(DiscoveredPrinter(
            name: 'Network Printer ($ip)',
            connectionType: ConnectionType.network,
            identifier: ip,
            port: port,
          ));
        }
      }));
    }

    await Future.wait(tasks);
    return found;
  }

  static Future<bool> _testPort(String ip, int port, Duration timeout) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: timeout);
      await socket.close();
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
