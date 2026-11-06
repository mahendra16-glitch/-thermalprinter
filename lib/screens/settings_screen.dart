import 'package:flutter/material.dart';

import '../models/print_mode.dart';
import '../services/storage_service.dart';
import '../services/pos_integration_service.dart';
import 'diagnostics_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPrintMode();
    _loadSampleJson();
  }

  Future<void> _loadPrintMode() async {
    final storage = await StorageService.getInstance();
    final mode = await storage.getPrintMode();
    if (mounted) {
      setState(() => _currentMode = mode);
    }
  }

  Future<void> _setPrintMode(PrintMode mode) async {
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
      appBar: AppBar(title: const Text('Printer Settings & Integration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _loadSampleJson,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reset Sample'),
                ),
                const Spacer(),
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
