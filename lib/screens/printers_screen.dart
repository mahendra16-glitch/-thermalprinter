import 'package:flutter/material.dart';
import '../models/printer_device.dart';
import '../services/storage_service.dart';
import '../widgets/printer_card.dart';
import 'add_edit_printer_screen.dart';

class PrintersScreen extends StatefulWidget {
  const PrintersScreen({super.key});

  @override
  State<PrintersScreen> createState() => _PrintersScreenState();
}

class _PrintersScreenState extends State<PrintersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PrinterDevice> _printers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() => _isLoading = true);
    final storage = await StorageService.getInstance();
    final list = await storage.getSavedPrinters();
    if (mounted) {
      setState(() {
        _printers = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePrinter(String printerId) async {
    final storage = await StorageService.getInstance();
    await storage.deletePrinter(printerId);
    _loadPrinters();
  }

  void _openAddPrinter() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditPrinterScreen()),
    );
    if (result == true) {
      _loadPrinters();
    }
  }

  void _openEditPrinter(PrinterDevice device) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => AddEditPrinterScreen(printerToEdit: device)),
    );
    if (result == true) {
      _loadPrinters();
    }
  }

  List<PrinterDevice> _getFilteredPrinters(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _printers
            .where((p) => p.connectionType == ConnectionType.bluetooth)
            .toList();
      case 2:
        return _printers
            .where((p) => p.connectionType == ConnectionType.usb)
            .toList();
      case 3:
        return _printers
            .where((p) => p.connectionType == ConnectionType.network)
            .toList();
      default:
        return _printers;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Thermal Printers'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Bluetooth'),
            Tab(text: 'USB'),
            Tab(text: 'Wi-Fi / LAN'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: List.generate(4, (index) {
                final filtered = _getFilteredPrinters(index);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.print_disabled_rounded,
                            size: 48, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        const Text(
                          'No printers configured for this tab.',
                          style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openAddPrinter,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('+ Add Printer'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final printer = filtered[idx];
                    return PrinterCard(
                      printer: printer,
                      onEdit: () => _openEditPrinter(printer),
                      onDelete: () => _deletePrinter(printer.id),
                      onUpdated: () => setState(() {}),
                    );
                  },
                );
              }),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPrinter,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('+ Add Printer', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
