import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/printer_device.dart';
import '../models/print_mode.dart';
import '../models/print_job.dart';
import '../models/print_history_item.dart';

class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Saved Printers ---

  Future<List<PrinterDevice>> getSavedPrinters() async {
    final String? raw = _prefs?.getString(AppConstants.keySavedPrinters);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list
          .map((e) => PrinterDevice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> savePrinter(PrinterDevice printer) async {
    final printers = await getSavedPrinters();
    final index = printers.indexWhere((p) => p.id == printer.id);
    if (index >= 0) {
      printers[index] = printer;
    } else {
      printers.add(printer);
    }
    await _savePrinterList(printers);
  }

  Future<void> deletePrinter(String printerId) async {
    final printers = await getSavedPrinters();
    printers.removeWhere((p) => p.id == printerId);
    await _savePrinterList(printers);
  }

  Future<void> _savePrinterList(List<PrinterDevice> printers) async {
    final raw = jsonEncode(printers.map((p) => p.toJson()).toList());
    await _prefs?.setString(AppConstants.keySavedPrinters, raw);
  }

  Future<PrinterDevice?> getPrinterForRole(PrinterRole role) async {
    final printers = await getSavedPrinters();
    try {
      return printers.firstWhere((p) => p.role == role);
    } catch (_) {
      return printers.isNotEmpty ? printers.first : null;
    }
  }

  // --- Print Mode ---

  Future<PrintMode> getPrintMode() async {
    final String? modeName = _prefs?.getString(AppConstants.keyPrintMode);
    if (modeName == null) return PrintMode.compatibilityMode;
    return PrintMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => PrintMode.compatibilityMode,
    );
  }

  Future<void> setPrintMode(PrintMode mode) async {
    await _prefs?.setString(AppConstants.keyPrintMode, mode.name);
  }

  // --- Print Queue ---

  Future<List<PrintJob>> getQueue() async {
    final String? raw = _prefs?.getString(AppConstants.keyPrintQueue);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list
          .map((e) => PrintJob.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveQueue(List<PrintJob> queue) async {
    final raw = jsonEncode(queue.map((j) => j.toJson()).toList());
    await _prefs?.setString(AppConstants.keyPrintQueue, raw);
  }

  // --- Print History ---

  Future<List<PrintHistoryItem>> getHistory() async {
    final String? raw = _prefs?.getString(AppConstants.keyPrintHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list
          .map((e) => PrintHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addHistoryItem(PrintHistoryItem item) async {
    final history = await getHistory();
    history.insert(0, item); // latest first
    if (history.length > 200) {
      history.removeLast(); // keep last 200 records
    }
    final raw = jsonEncode(history.map((h) => h.toJson()).toList());
    await _prefs?.setString(AppConstants.keyPrintHistory, raw);
  }

  Future<void> clearHistory() async {
    await _prefs?.remove(AppConstants.keyPrintHistory);
  }
}
