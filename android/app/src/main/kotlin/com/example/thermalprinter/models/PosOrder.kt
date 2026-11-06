package com.example.thermalprinter.models

data class PosOrderItem(
    val name: String,
    val qty: Int,
    val price: Double = 0.0,
    val notes: String? = null,
    val addOns: List<String> = emptyList()
)

data class PosOrder(
    val orderId: String,
    val billNo: String = orderId,
    val type: String = "BILL", // "BILL" or "KOT"
    val targetRole: PrinterRole = PrinterRole.BILL,
    val restaurantName: String = "MYGENIE RESTAURANT",
    val customerName: String? = "Rahul Sharma",
    val customerPhone: String? = "9876543210",
    val customerAddress: String? = null,
    val tableNumber: String? = "T-05",
    val roomNumber: String? = null,
    val waiterName: String? = "Rahul",
    val orderType: String = "DINE-IN", // DINE-IN, TAKEAWAY, DELIVERY
    val items: List<PosOrderItem>,
    val subtotal: Double = 0.0,
    val cgst: Double = 0.0,
    val sgst: Double = 0.0,
    val discount: Double = 0.0,
    val total: Double = 0.0,
    val paymentMethod: String = "UPI",
    val paymentStatus: String = "✓ PAID",
    val specialNotes: String? = null,
    val timestamp: Long = System.currentTimeMillis()
)
