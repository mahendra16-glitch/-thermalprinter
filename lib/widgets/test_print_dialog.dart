import 'package:flutter/material.dart';
import '../models/printer_device.dart';
import '../models/print_mode.dart';
import '../services/storage_service.dart';
import '../printing/test_receipt_generator.dart';
import '../printing/smart_print_engine.dart';

class TestPrintDialog extends StatefulWidget {
  final PrinterDevice device;

  const TestPrintDialog({super.key, required this.device});

  @override
  State<TestPrintDialog> createState() => _TestPrintDialogState();
}

class _TestPrintDialogState extends State<TestPrintDialog> {
  PrintMode _selectedMode = PrintMode.compatibilityMode;
  bool _isPrinting = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadPrintMode();
  }

  Future<void> _loadPrintMode() async {
    final storage = await StorageService.getInstance();
    final mode = await storage.getPrintMode();
    if (mounted) {
      setState(() {
        _selectedMode = mode;
      });
    }
  }

  Future<void> _runTestPrint() async {
    setState(() {
      _isPrinting = true;
      _errorMessage = null;
      _isSuccess = false;
    });

    final testOrder = TestReceiptGenerator.buildTestOrder(widget.device);

    try {
      await SmartPrintEngine.printOrder(
        order: testOrder,
        device: widget.device,
        printMode: _selectedMode,
      );

      if (mounted) {
        setState(() {
          _isPrinting = false;
          _isSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPrinting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.print_rounded, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Test Print: ${widget.device.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Printer: ${widget.device.connectionType.name.toUpperCase()} (${widget.device.paperWidth.label})',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Print Engine Mode:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...PrintMode.values.map((mode) {
              return RadioListTile<PrintMode>(
                value: mode,
                groupValue: _selectedMode,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  mode.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  mode.description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                onChanged: _isPrinting
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedMode = val;
                          });
                        }
                      },
              );
            }),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_isSuccess) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Test page printed successfully!',
                        style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isPrinting ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _isPrinting ? null : _runTestPrint,
          child: _isPrinting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Send Test Page'),
        ),
      ],
    );
  }
}
