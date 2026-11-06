import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/print_history_item.dart';
import '../services/storage_service.dart';
import '../queue/print_queue_manager.dart';
import '../printing/test_receipt_generator.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<PrintHistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final storage = await StorageService.getInstance();
    final list = await storage.getHistory(limit: 500);
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final storage = await StorageService.getInstance();
    await storage.clearHistory();
    _loadHistory();
  }

  Future<void> _reprint(PrintHistoryItem item) async {
    final printers = await (await StorageService.getInstance())
        .getSavedPrinters();
    final printer = printers.firstWhere(
      (p) => p.name == item.printerName,
      orElse: () => printers.isNotEmpty
          ? printers.first
          : throw Exception('No printer found'),
    );

    final order = TestReceiptGenerator.buildTestOrder(printer);
    final queueManager = await PrintQueueManager.getInstance();
    await queueManager.addOrderToQueue(order);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reprint job for Order #${item.orderId} added to queue',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print History Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear History Log',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Print History?'),
                  content: const Text(
                    'This will delete all historical print log records.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete All'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _clearHistory();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 48,
                    color: Color(0xFFCBD5E1),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No print history records found.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _history.length,
              itemBuilder: (context, idx) {
                final item = _history[idx];
                final DateFormat formatter = DateFormat('dd MMM yyyy, hh:mm a');

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.isSuccess
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      child: Icon(
                        item.isSuccess
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        color: item.isSuccess ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      'Order #${item.orderId} (${item.printType})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Printer: ${item.printerName} (${item.connectionType.name.toUpperCase()})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                        Text(
                          formatter.format(item.timestamp),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        if (item.errorMessage != null)
                          Text(
                            item.errorMessage!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                    trailing: OutlinedButton(
                      onPressed: () => _reprint(item),
                      child: const Text(
                        'Reprint',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
