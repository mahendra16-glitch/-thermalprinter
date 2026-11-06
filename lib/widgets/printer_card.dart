import 'package:flutter/material.dart';

import '../models/printer_device.dart';
import '../printers/printer_adapter.dart';
import 'status_badge.dart';
import 'test_print_dialog.dart';

class PrinterCard extends StatefulWidget {
  final PrinterDevice printer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUpdated;

  const PrinterCard({
    super.key,
    required this.printer,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdated,
  });

  @override
  State<PrinterCard> createState() => _PrinterCardState();
}

class _PrinterCardState extends State<PrinterCard> {
  bool _isConnecting = false;
  String? _statusError;

  Future<void> _toggleConnection() async {
    setState(() {
      _isConnecting = true;
      _statusError = null;
    });

    final adapter = PrinterAdapter.forDevice(widget.printer);

    try {
      if (widget.printer.isConnected) {
        await adapter.disconnect();
        widget.printer.isConnected = false;
      } else {
        await adapter.connect();
        widget.printer.isConnected = true;
      }
    } catch (e) {
      _statusError = e.toString().replaceAll('Exception: ', '');
      widget.printer.isConnected = false;
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        widget.onUpdated();
      }
    }
  }

  void _showTestPrintDialog() {
    showDialog(
      context: context,
      builder: (ctx) => TestPrintDialog(device: widget.printer),
    );
  }

  String _getConnectionDetails() {
    switch (widget.printer.connectionType) {
      case ConnectionType.bluetooth:
        return widget.printer.macAddress ?? 'No MAC Address';
      case ConnectionType.usb:
        return widget.printer.deviceName ??
            'VID:${widget.printer.vendorId ?? "N/A"} PID:${widget.printer.productId ?? "N/A"}';
      case ConnectionType.network:
        return '${widget.printer.ipAddress ?? "0.0.0.0"}:${widget.printer.port}';
    }
  }

  IconData _getConnectionIcon() {
    switch (widget.printer.connectionType) {
      case ConnectionType.bluetooth:
        return Icons.bluetooth_rounded;
      case ConnectionType.usb:
        return Icons.usb_rounded;
      case ConnectionType.network:
        return Icons.wifi_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.printer;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Printer Name & Role Badge
            Row(
              children: [
                Icon(
                  _getConnectionIcon(),
                  color: const Color(0xFF2563EB),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.role.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Connection Info & Width
            Row(
              children: [
                Text(
                  'Type: ${p.connectionType.name.toUpperCase()}  |  Width: ${p.paperWidth.label}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Details: ${_getConnectionDetails()}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 12),

            // Status Badge & Last Error
            Row(
              children: [
                if (_isConnecting)
                  StatusBadge.connecting()
                else if (p.isConnected)
                  StatusBadge.connected()
                else
                  StatusBadge.disconnected(),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _showTestPrintDialog,
                  icon: const Icon(Icons.print, size: 14),
                  label: const Text(
                    'Test Print',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ),
              ],
            ),

            if (_statusError != null || p.lastError != null) ...[
              const SizedBox(height: 8),
              Text(
                _statusError ?? p.lastError!,
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            ],

            const Divider(height: 20),

            // Action Buttons
            Row(
              children: [
                OutlinedButton(
                  onPressed: _isConnecting ? null : _toggleConnection,
                  child: Text(
                    p.isConnected ? 'Disconnect' : 'Connect',
                    style: TextStyle(
                      fontSize: 12,
                      color: p.isConnected
                          ? Colors.red
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                  onPressed: widget.onEdit,
                  tooltip: 'Edit Printer',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red,
                  ),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete Printer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
