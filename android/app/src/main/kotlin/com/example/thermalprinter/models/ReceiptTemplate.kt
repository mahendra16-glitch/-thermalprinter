package com.example.thermalprinter.models

data class ReceiptTemplate(
    val restaurantName: String = "MYGENIE RESTAURANT",
    val billTitle: String = "★ CUSTOMER BILL ★",
    val kotTitle: String = "🔥 KITCHEN KOT 🔥",
    val address: String = "123 Main Street, City Center",
    val phone: String = "+91 9876543210",
    val gstin: String? = "27AAAAA0000A1Z5",
    val fssai: String? = "10019022009876",
    val headerMessage: String = "Welcome to MYGENIE Restaurant",
    val footerMessage: String = "Thank You 😊\n★ Visit Again ★\nधन्यवाद 🙏",
    val showLogo: Boolean = true,
    val showQrCode: Boolean = true,
    val showCustomerDetails: Boolean = true,
    val showGstDetails: Boolean = true
)
