import 'package:flutter/material.dart';

import '../models/pos_order.dart';
import '../models/printer_device.dart';
import '../services/storage_service.dart';
import '../services/native_engine_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _restaurantController = TextEditingController(
    text: 'MYGENIE RESTAURANT',
  );
  final _customerController = TextEditingController(
    text: 'महेंद्र कुमार (Rahul)',
  );
  final _phoneController = TextEditingController(text: '9876543210');
  final _tableController = TextEditingController(text: 'T-05');
  final _instructionsController = TextEditingController(
    text: 'NO ONION - CUSTOMER ALLERGY 🔥',
  );

  List<PrinterDevice> _printers = [];
  PrinterDevice? _selectedPrinter;
  bool _isProcessing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    final storage = await StorageService.getInstance();
    final list = await storage.getSavedPrinters();
    if (mounted) {
      setState(() {
        _printers = list;
        if (list.isNotEmpty) _selectedPrinter = list.first;
      });
    }
  }

  PosOrder _buildTestOrder({required String type}) {
    return PosOrder(
      orderId: '1024',
      billNo: '1024',
      type: type,
      restaurantName: _restaurantController.text,
      customerName: _customerController.text,
      customerPhone: _phoneController.text,
      tableNumber: _tableController.text,
      orderType: 'DINE-IN',
      waiterName: 'Rahul',
      specialNotes: _instructionsController.text,
      items: [
        PosOrderItem(
          name: 'Paneer Tikka 🌶️',
          qty: 2,
          price: 180.0,
          notes: 'Extra Spicy 🔥',
        ),
        PosOrderItem(
          name: 'Veg Burger 🍔',
          qty: 1,
          price: 150.0,
          notes: 'Extra Cheese 🧀',
        ),
        PosOrderItem(
          name: 'Cold Coffee ☕',
          qty: 2,
          price: 100.0,
          notes: 'Less Sugar',
        ),
        PosOrderItem(name: 'चिकन बिरयानी 🌶️', qty: 1, price: 250.0),
      ],
      subtotal: 710.0,
      cgst: 17.75,
      sgst: 17.75,
      discount: 20.0,
      total: 725.50,
      paymentMethod: 'UPI',
      paymentStatus: '✓ PAID',
    );
  }

  Future<void> _runAction(Future<bool> Function() action) async {
    if (_selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add and select a printer first.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final success = await action();
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = success
              ? 'Print action executed successfully! 🟢'
              : 'Print action failed. 🔴';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Development & Print Quality Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Printer Selector
            const Text(
              'Select Target Thermal Printer:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            if (_printers.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No printers saved yet. Please add a printer in the Printers tab first.',
                  style: TextStyle(color: Colors.amber),
                ),
              )
            else
              DropdownButtonFormField<PrinterDevice>(
                value: _selectedPrinter,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _printers.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(
                      '${p.name} (${p.connectionType.name.toUpperCase()} - ${p.paperWidth.label})',
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPrinter = val),
              ),
            const SizedBox(height: 16),

            // Text Inputs
            TextField(
              controller: _restaurantController,
              decoration: const InputDecoration(
                labelText: 'Restaurant Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _customerController,
              decoration: const InputDecoration(
                labelText: 'Customer Name (Hindi/Unicode)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _tableController,
                    decoration: const InputDecoration(
                      labelText: 'Table',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Special Notes / Allergy',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _statusMessage!.contains('successfully')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _statusMessage!.contains('successfully')
                        ? Colors.green.shade900
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            const Text(
              'Interactive Acceptance Tests:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _runAction(
                          () => NativeEngineService.printNativeOrder(
                            order: _buildTestOrder(type: 'BILL'),
                            device: _selectedPrinter!,
                          ),
                        ),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('PRINT BILL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _runAction(
                          () => NativeEngineService.printNativeOrder(
                            order: _buildTestOrder(type: 'KOT'),
                            device: _selectedPrinter!,
                          ),
                        ),
                  icon: const Icon(Icons.soup_kitchen_rounded),
                  label: const Text('PRINT KOT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _runAction(
                          () => NativeEngineService.runCalibration(
                            _selectedPrinter!,
                          ),
                        ),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('CALIBRATION SHEET'),
                ),
                OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _runAction(
                          () => NativeEngineService.printNativeOrder(
                            order: PosOrder(
                              orderId: 'EMOJI-1',
                              restaurantName: 'EMOJI TEST 😊',
                              items: [
                                PosOrderItem(name: 'Paneer Tikka 🌶️', qty: 2),
                                PosOrderItem(name: 'Veg Burger 🍔', qty: 1),
                                PosOrderItem(name: 'Cold Coffee ☕', qty: 2),
                              ],
                              total: 450.0,
                              paymentStatus: '✓ PAID 🙏',
                            ),
                            device: _selectedPrinter!,
                          ),
                        ),
                  icon: const Icon(Icons.emoji_emotions_rounded),
                  label: const Text('TEST EMOJI'),
                ),
                OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _runAction(
                          () => NativeEngineService.printNativeOrder(
                            order: PosOrder(
                              orderId: 'SYM-1',
                              restaurantName: 'SYMBOLS TEST',
                              items: [
                                PosOrderItem(
                                  name: 'Special Item ₹100.00',
                                  qty: 1,
                                ),
                              ],
                              paymentStatus: '✓ PAID ★ ♥ → © ™',
                            ),
                            device: _selectedPrinter!,
                          ),
                        ),
                  icon: const Icon(Icons.star_rounded),
                  label: const Text('TEST SYMBOLS'),
                ),
                OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _runAction(
                          () => NativeEngineService.printNativeOrder(
                            order: PosOrder(
                              orderId: 'HINDI-1',
                              restaurantName: 'मायजीनी रेस्तरां',
                              customerName: 'महेंद्र कुमार',
                              items: [
                                PosOrderItem(
                                  name: 'चिकन बिरयानी 🌶️',
                                  qty: 2,
                                  price: 250.0,
                                ),
                                PosOrderItem(
                                  name: 'पनीर टिक्का ⭐',
                                  qty: 1,
                                  price: 180.0,
                                ),
                              ],
                              total: 680.0,
                              paymentStatus: 'धन्यवाद 🙏',
                            ),
                            device: _selectedPrinter!,
                          ),
                        ),
                  icon: const Icon(Icons.translate_rounded),
                  label: const Text('TEST HINDI'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
