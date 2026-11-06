import '../models/pos_order.dart';
import '../models/print_mode.dart';
import '../models/printer_device.dart';
import '../printers/printer_adapter.dart';
import 'receipt_layouts.dart';
import 'receipt_renderer.dart';

class SmartPrintEngine {
  /// Renders [order] for [device] and sends it. Throws if the transport
  /// reports a failure. A successful return means every byte was accepted
  /// by the connection; it cannot prove that paper came out.
  static Future<void> printOrder({
    required PosOrder order,
    required PrinterDevice device,
    required PrintMode printMode,
  }) async {
    final bytes = await generateOrderBytes(
      order: order,
      device: device,
      printMode: printMode,
    );
    final adapter = PrinterAdapter.forDevice(device);
    try {
      await adapter.sendRawBytes(bytes);
    } finally {
      await adapter.disconnect();
    }
  }

  /// Builds the bytes for [order] (KOT, bill or printer test page).
  static Future<List<int>> generateOrderBytes({
    required PosOrder order,
    required PrinterDevice device,
    required PrintMode printMode,
  }) {
    final doc = ReceiptLayouts.forOrder(order, device);
    return ReceiptRenderer(RenderOptions.forDevice(device, printMode))
        .render(doc);
  }
}
