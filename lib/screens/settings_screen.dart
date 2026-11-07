import 'package:flutter/material.dart';

import '../domain/staff/staff_models.dart';
import '../features/billing/billing_settings_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/staff/permission_guard.dart';
import '../features/staff/staff_screen.dart';
import '../models/print_mode.dart';
import '../models/printer_device.dart';
import '../services/storage_service.dart';
import '../services/pos_integration_service.dart';
import 'backup_screen.dart';
import 'business_profile_screen.dart';
import 'diagnostics_screen.dart';
import 'error_log_screen.dart';
import 'history_screen.dart';
import 'printers_screen.dart';
import 'queue_screen.dart';
import 'test_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PrintMode _currentMode = PrintMode.compatibilityMode;
  final TextEditingController _jsonController = TextEditingController();
  bool _isSendingPosJob = false;
  String? _posResult;
  List<PrinterDevice> _printers = [];
  String? _fallbackPrinterId;
  int _dayStartHour = 0;

  /// Bumped to redraw a dropdown with its saved value when a change was
  /// not allowed.
  int _rev = 0;

  @override
  void initState() {
    super.initState();
    _loadPrintMode();
    _loadFallback();
    _loadSampleJson();
  }

  Future<void> _loadFallback() async {
    final storage = await StorageService.getInstance();
    final printers = await storage.getSavedPrinters();
    final fallback = await storage.settings.getFallbackPrinterId();
    final dayStart = await storage.orders.getDayStartHour();
    if (mounted) {
      setState(() {
        _printers = printers;
        _dayStartHour = dayStart;
        _fallbackPrinterId = printers.any((p) => p.id == fallback)
            ? fallback
            : null;
      });
    }
  }

  Future<void> _setFallback(String? printerId) async {
    if (!await allow(context, Permission.changePrinterSettings)) {
      if (mounted) setState(() => _rev++);
      return;
    }
    final storage = await StorageService.getInstance();
    await storage.settings.setFallbackPrinterId(printerId);
    if (mounted) setState(() => _fallbackPrinterId = printerId);
  }

  Widget _navTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget Function() page,
    Permission? permission,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () async {
        if (permission != null && !await allow(context, permission)) return;
        if (!mounted) return;
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => page()));
        _loadFallback();
      },
    );
  }

  Widget _buildBusinessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _navTile(
          icon: Icons.badge_rounded,
          color: const Color(0xFF0369A1),
          title: 'Staff',
          subtitle: 'Staff accounts, PIN sign-in, roles and activity log.',
          page: () => const StaffScreen(),
          permission: Permission.manageStaff,
        ),
        _navTile(
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF65A30D),
          title: 'Stock',
          subtitle: 'Ingredients, stock in, wastage, counts, low-stock alerts.',
          page: () => const InventoryScreen(),
        ),
        _navTile(
          icon: Icons.storefront_rounded,
          color: const Color(0xFF0F766E),
          title: 'Business Profile',
          subtitle: 'Restaurant name, address, phone, GSTIN, FSSAI, UPI ID.',
          page: () => const BusinessProfileScreen(),
          permission: Permission.changeSettings,
        ),
        _navTile(
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFFEA580C),
          title: 'Billing & tax',
          subtitle: 'Service charge, rounding, bill numbers, tax rates.',
          page: () => const BillingSettingsScreen(),
          permission: Permission.changeSettings,
        ),
        _navTile(
          icon: Icons.backup_rounded,
          color: const Color(0xFF7C3AED),
          title: 'Backup & restore',
          subtitle: 'Verified, optionally password-protected copies; restore.',
          page: () => const BackupScreen(),
          permission: Permission.backupRestore,
        ),
        _navTile(
          icon: Icons.print_rounded,
          color: const Color(0xFF1E293B),
          title: 'Printers',
          subtitle: 'Bluetooth, USB and Wi-Fi/LAN printers.',
          page: () => const PrintersScreen(),
          permission: Permission.changePrinterSettings,
        ),
        _navTile(
          icon: Icons.queue_rounded,
          color: const Color(0xFF2563EB),
          title: 'Print queue',
          subtitle: 'Pending and failed print jobs, retry.',
          page: () => const QueueScreen(),
        ),
        _navTile(
          icon: Icons.history_rounded,
          color: const Color(0xFF475569),
          title: 'Print history',
          subtitle: 'Every print attempt and its result.',
          page: () => const HistoryScreen(),
        ),
        const SizedBox(height: 16),
        const Text(
          'Business day starts at',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Order numbers restart each business day. If you serve after '
          'midnight, start the day later so late orders count towards the '
          'evening they belong to.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          key: ValueKey('day-$_dayStartHour-$_rev'),
          initialValue: _dayStartHour,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: [
            for (var h = 0; h <= 6; h++)
              DropdownMenuItem(
                value: h,
                child: Text(h == 0 ? 'Midnight (12:00 am)' : '$h:00 am'),
              ),
          ],
          onChanged: (v) async {
            if (v == null) return;
            if (!await allow(context, Permission.changeSettings)) {
              if (mounted) setState(() => _rev++); // put the saved value back
              return;
            }
            final storage = await StorageService.getInstance();
            await storage.orders.setDayStartHour(v);
            if (mounted) setState(() => _dayStartHour = v);
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Fallback printer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          "Used when a job's role (e.g. Kitchen) has no printer assigned. "
          'With "None", such jobs fail and show the reason in the queue.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          key: ValueKey('fallback-$_fallbackPrinterId-$_rev'),
          initialValue: _fallbackPrinterId,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('None (fail if no printer for the role)'),
            ),
            ..._printers.map(
              (p) => DropdownMenuItem<String?>(
                value: p.id,
                child: Text('${p.name} (${p.role.label})'),
              ),
            ),
          ],
          onChanged: _setFallback,
        ),
        const Divider(height: 32),
      ],
    );
  }

  Future<void> _loadPrintMode() async {
    final storage = await StorageService.getInstance();
    final mode = await storage.getPrintMode();
    if (mounted) {
      setState(() => _currentMode = mode);
    }
  }

  Future<void> _setPrintMode(PrintMode mode) async {
    if (!await allow(context, Permission.changePrinterSettings)) return;
    final storage = await StorageService.getInstance();
    await storage.setPrintMode(mode);
    setState(() => _currentMode = mode);
  }

  void _loadSampleJson() {
    _jsonController.text = '''{
  "orderId": "1024",
  "type": "KOT",
  "printerRole": "kitchen",
  "restaurantName": "MYGENIE RESTAURANT ❤️",
  "tableNumber": "Table 05",
  "items": [
    {
      "name": "Paneer Tikka 🌶️🌶️",
      "qty": 2,
      "price": 220.0
    },
    {
      "name": "Veg Burger 🍔",
      "qty": 1,
      "price": 90.0
    },
    {
      "name": "Cold Coffee ☕",
      "qty": 2,
      "price": 140.0
    }
  ],
  "subtotal": 450.0,
  "tax": 22.5,
  "total": 472.5,
  "paymentStatus": "PAID ✓"
}''';
  }

  Future<void> _sendTestPosOrder() async {
    setState(() {
      _isSendingPosJob = true;
      _posResult = null;
    });

    try {
      final jobId = await PosIntegrationService.processIncomingPrintJob(
        _jsonController.text,
      );

      if (mounted) {
        setState(() {
          _isSendingPosJob = false;
          _posResult = 'POS Job Enqueued Successfully! Job ID: $jobId';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingPosJob = false;
          _posResult = 'POS Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBusinessSection(),

            // Smart Print Engine Mode
            const Text(
              'Smart Print Engine Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Controls how text, emojis, and symbols are converted to ESC/POS byte streams.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 12),

            ...PrintMode.values.map((mode) {
              final isSelected = mode == _currentMode;
              return Card(
                color: isSelected
                    ? const Color(0xFF2563EB).withOpacity(0.08)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: RadioListTile<PrintMode>(
                  value: mode,
                  groupValue: _currentMode,
                  title: Text(
                    mode.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    mode.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) _setPrintMode(val);
                  },
                ),
              );
            }),

            const Divider(height: 32),

            // POS Integration & API Payload Tester
            const Text(
              'POS Integration Payload Tester',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Simulate incoming print jobs from external POS apps, web apps, or APIs.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _jsonController,
              maxLines: 10,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Structured POS Order JSON Payload',
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _loadSampleJson,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reset Sample'),
                ),
                ElevatedButton.icon(
                  onPressed: _isSendingPosJob ? null : _sendTestPosOrder,
                  icon: _isSendingPosJob
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Enqueue Print Job'),
                ),
              ],
            ),

            if (_posResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _posResult!.contains('Error')
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _posResult!,
                  style: TextStyle(
                    color: _posResult!.contains('Error')
                        ? Colors.red
                        : Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],

            const Divider(height: 32),

            // Print Quality Test & Calibration Wizard
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2563EB),
                child: Icon(Icons.tune_rounded, color: Colors.white),
              ),
              title: const Text(
                'Interactive Print Quality & Acceptance Test',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Test BILL, KOT, Emoji, Hindi, Special symbols & print Calibration sheet.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const TestScreen()));
              },
            ),

            const Divider(height: 32),

            _navTile(
              icon: Icons.report_gmailerrorred_rounded,
              color: const Color(0xFFB91C1C),
              title: 'App error log',
              subtitle:
                  'Unexpected errors saved on this device; share or clear.',
              page: () => const ErrorLogScreen(),
            ),
            const Divider(height: 32),

            // Printer Diagnostics
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1E293B),
                child: Icon(Icons.bug_report_rounded, color: Colors.white),
              ),
              title: const Text(
                'Printer Diagnostics & Support',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Inspect raw connection data, vendor IDs, queue status & export reports.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
