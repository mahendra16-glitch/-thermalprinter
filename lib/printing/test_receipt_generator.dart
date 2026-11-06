import '../models/printer_device.dart';
import '../models/pos_order.dart';

class TestReceiptGenerator {
  /// Builds a sample POS order representing the test print page requirements
  static PosOrder buildTestOrder(PrinterDevice device) {
    return PosOrder(
      orderId: 'TEST-1024',
      type: 'PRINTER_TEST',
      printerRole: device.role,
      restaurantName: 'MYGENIE PRINTER TEST',
      tableNumber: 'Table 05',
      waiterName: 'Staff',
      items: [
        PosOrderItem(name: 'Paneer Tikka 🌶️🌶️', qty: 2, price: 220.0),
        PosOrderItem(name: 'Veg Burger 🍔', qty: 1, price: 90.0),
        PosOrderItem(name: 'Cold Coffee ☕', qty: 2, price: 140.0),
      ],
      subtotal: 450.0,
      tax: 22.50,
      total: 472.50,
      paymentStatus: 'PAID ✓',
    );
  }
}
