package com.example.thermalprinter.calibration

import android.content.Context
import android.text.Layout
import com.example.thermalprinter.PrinterManager
import com.example.thermalprinter.engine.EscPosEncoder
import com.example.thermalprinter.engine.ThermalRasterEngine
import com.example.thermalprinter.models.PrinterProfile

class CalibrationWizard(private val context: Context) {

    fun printCalibrationSheet(profile: PrinterProfile): Boolean {
        val encoder = EscPosEncoder(profile)
        val rasterEngine = ThermalRasterEngine(profile)

        // Header
        encoder.alignCenter().bold(true).text("THERMAL PRINTER CALIBRATION SHEET")
        encoder.text("Printer: ${profile.name} (${profile.paperWidth.name})")
        encoder.divider()

        // 1. Text Quality Test
        val textTest = "TEXT QUALITY TEST\nNormal Text\nMedium Text\nBOLD TEXT\nEXTRA BOLD TEXT"
        val textRaster = rasterEngine.renderTextToRasterBytes(textTest, textSizeSp = 20f, align = Layout.Alignment.ALIGN_CENTER)
        encoder.appendRawBytes(textRaster)
        encoder.divider()

        // 2. Special Characters Test
        val symbols = "CURRENCY & SYMBOLS TEST\n₹100.00  ✓ PAID  ★ 5-STAR\n♥ → ← © ™ ° •"
        val symbolRaster = rasterEngine.renderTextToRasterBytes(symbols, textSizeSp = 20f, align = Layout.Alignment.ALIGN_CENTER)
        encoder.appendRawBytes(symbolRaster)
        encoder.divider()

        // 3. Emojis Test
        val emojis = "EMOJI RASTER TEST\n😊 ❤️ 🔥 🌶️ 🍔 🍕 ☕ 🙏 ⭐ ✅"
        val emojiRaster = rasterEngine.renderTextToRasterBytes(emojis, textSizeSp = 22f, align = Layout.Alignment.ALIGN_CENTER)
        encoder.appendRawBytes(emojiRaster)
        encoder.divider()

        // 4. Hindi Text Test
        val hindi = "HINDI UNICODE TEST\nनमस्ते  |  धन्यवाद 🙏\nमायजीनी रेस्तरां"
        val hindiRaster = rasterEngine.renderTextToRasterBytes(hindi, textSizeSp = 22f, align = Layout.Alignment.ALIGN_CENTER)
        encoder.appendRawBytes(hindiRaster)
        encoder.divider()

        // 5. Threshold Scale Grid Test
        val thresholdScale = "THRESHOLD SCALE TEST\n120 ██████████████ (Darker)\n140 ██████████████\n160 ██████████████ (Default)\n180 ██████████████\n200 ██████████████ (Lighter)"
        val thresholdRaster = rasterEngine.renderTextToRasterBytes(thresholdScale, textSizeSp = 18f)
        encoder.appendRawBytes(thresholdRaster)
        encoder.divider()

        encoder.alignCenter().text("CURRENT PROFILE SETTINGS:")
        encoder.text("Darkness: ${profile.darknessPreset.name}")
        encoder.text("Threshold: ${profile.bitmapThreshold}")
        encoder.text("Font Weight: ${if (profile.fontWeightBold) "BOLD" else "NORMAL"}")
        encoder.text("Line Spacing: ${profile.lineSpacingPx}px")
        encoder.divider()

        encoder.cut()

        val bytes = encoder.build()
        val manager = PrinterManager(context)
        val transport = manager.getTransport(profile)

        return try {
            transport.sendBytes(bytes)
        } finally {
            transport.disconnect()
        }
    }
}
