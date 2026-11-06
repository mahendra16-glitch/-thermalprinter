import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/storage_service.dart';
import '../queue/print_queue_manager.dart';
import '../models/printer_device.dart';
import '../models/print_mode.dart';

class DiagnosticsService {
  /// Assembles comprehensive diagnostic report string for customer support & debugging
  static Future<String> generateReport() async {
    final storage = await StorageService.getInstance();
    final queueManager = await PrintQueueManager.getInstance();
    final printers = await storage.getSavedPrinters();
    final printMode = await storage.getPrintMode();
    final queue = queueManager.currentQueue;
    final history = await storage.getHistory();

    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final StringBuffer sb = StringBuffer();

    sb.writeln('========================================');
    sb.writeln('    OFFLINE THERMAL PRINTER DIAGNOSTICS ');
    sb.writeln('========================================');
    sb.writeln('Generated At: ${formatter.format(DateTime.now())}');
    sb.writeln('Active Print Mode: ${printMode.title}');
    sb.writeln('Total Saved Printers: ${printers.length}');
    sb.writeln('Active Queue Size: ${queue.length}');
    sb.writeln('History Log Entries: ${history.length}');
    sb.writeln('----------------------------------------');

    sb.writeln('\n--- SAVED PRINTERS ---');
    if (printers.isEmpty) {
      sb.writeln('No saved printers found.');
    } else {
      for (int i = 0; i < printers.length; i++) {
        final p = printers[i];
        sb.writeln('\n[Printer #${i + 1}] ${p.name}');
        sb.writeln('  ID: ${p.id}');
        sb.writeln('  Role: ${p.role.label}');
        sb.writeln('  Type: ${p.connectionType.name.toUpperCase()}');
        sb.writeln('  Paper Width: ${p.paperWidth.label}');
        if (p.connectionType == ConnectionType.bluetooth) {
          sb.writeln('  MAC Address: ${p.macAddress ?? "N/A"}');
        } else if (p.connectionType == ConnectionType.usb) {
          sb.writeln(
            '  USB VID/PID: ${p.vendorId ?? "N/A"} / ${p.productId ?? "N/A"}',
          );
          sb.writeln('  Device Name: ${p.deviceName ?? "N/A"}');
        } else if (p.connectionType == ConnectionType.network) {
          sb.writeln('  IP Address: ${p.ipAddress ?? "N/A"}');
          sb.writeln('  Port: ${p.port}');
        }
        sb.writeln('  Connected: ${p.isConnected ? "YES 🟢" : "NO 🔴"}');
        if (p.lastConnected != null) {
          sb.writeln('  Last Connected: ${formatter.format(p.lastConnected!)}');
        }
        if (p.lastError != null) {
          sb.writeln('  Last Error: ${p.lastError}');
        }
      }
    }

    sb.writeln('\n----------------------------------------');
    sb.writeln('--- ACTIVE QUEUE SUMMARY ---');
    if (queue.isEmpty) {
      sb.writeln('Queue is empty.');
    } else {
      for (final j in queue) {
        sb.writeln(
          'Job [${j.id}] Order #${j.orderId} - Status: ${j.status.name.toUpperCase()} (Retries: ${j.retryCount})',
        );
        if (j.errorMessage != null) {
          sb.writeln('  Error: ${j.errorMessage}');
        }
      }
    }

    sb.writeln('\n----------------------------------------');
    sb.writeln('--- RECENT HISTORY (LAST 5) ---');
    final recentHistory = history.take(5).toList();
    if (recentHistory.isEmpty) {
      sb.writeln('No history records yet.');
    } else {
      for (final h in recentHistory) {
        sb.writeln(
          '${formatter.format(h.timestamp)} | ${h.printerName} | Order #${h.orderId} | ${h.isSuccess ? "SUCCESS ✓" : "FAILED ✗"}',
        );
        if (h.errorMessage != null) {
          sb.writeln('  Err: ${h.errorMessage}');
        }
      }
    }

    sb.writeln('\n========================================');
    sb.writeln('           END OF DIAGNOSTICS           ');
    sb.writeln('========================================');

    return sb.toString();
  }

  /// Copies report to clipboard
  static Future<void> copyReportToClipboard() async {
    final report = await generateReport();
    await Clipboard.setData(ClipboardData(text: report));
  }
}
