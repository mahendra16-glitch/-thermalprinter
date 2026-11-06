package com.example.thermalprinter.models

enum class ConnectionType { BLUETOOTH, USB, TCP }
enum class PaperWidth { MM58, MM80 }
enum class PrinterRole { BILL, KOT, CUSTOMER_COPY, BAR, KITCHEN, OTHER }
enum class DarknessPreset { NORMAL, DARK, EXTRA_DARK }

data class PrinterProfile(
    val id: String,
    val name: String,
    val connectionType: ConnectionType = ConnectionType.TCP,
    val macAddress: String? = null,
    val vendorId: Int? = null,
    val productId: Int? = null,
    val deviceName: String? = null,
    val ipAddress: String? = null,
    val port: Int = 9100,
    val paperWidth: PaperWidth = PaperWidth.MM80,
    val printableWidthDots: Int = if (paperWidth == PaperWidth.MM58) 384 else 576,
    val charsPerLine: Int = if (paperWidth == PaperWidth.MM58) 32 else 48,
    val role: PrinterRole = PrinterRole.BILL,
    
    // Quality & Raster Engine Settings
    val darknessPreset: DarknessPreset = DarknessPreset.EXTRA_DARK,
    val bitmapThreshold: Int = 150, // 120 (darker/more black) to 200 (lighter)
    val contrastMultiplier: Float = if (darknessPreset == DarknessPreset.EXTRA_DARK) 1.6f else if (darknessPreset == DarknessPreset.DARK) 1.3f else 1.0f,
    val fontWeightBold: Boolean = true,
    val lineSpacingPx: Int = 4,
    val ditheringEnabled: Boolean = true,
    val emojiSizePx: Int = 36,
    val kotFontSize: String = "LARGE", // NORMAL, LARGE, EXTRA_LARGE
    
    var isConnected: Boolean = false,
    var lastConnectedTime: Long? = null,
    var lastError: String? = null
)
