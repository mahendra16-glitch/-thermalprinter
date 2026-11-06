package com.example.thermalprinter.engine

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import com.example.thermalprinter.models.DarknessPreset
import com.example.thermalprinter.models.PrinterProfile

class ThermalRasterEngine(private val profile: PrinterProfile) {

    /// Renders text (supporting Hindi, Emojis, Symbols) into sharp 1-bit ESC/POS raster commands
    fun renderTextToRasterBytes(
        text: String,
        textSizeSp: Float = 20f,
        isBold: Boolean = false,
        align: Layout.Alignment = Layout.Alignment.ALIGN_NORMAL
    ): ByteArray {
        val width = profile.printableWidthDots

        val textPaint = TextPaint().apply {
            color = Color.BLACK
            textSize = textSizeSp * 1.8f // Scale up for thermal resolution
            isAntiAlias = true
            isSubpixelText = true
            typeface = if (isBold || profile.fontWeightBold) {
                Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            } else {
                Typeface.DEFAULT
            }
        }

        val staticLayout = StaticLayout.Builder
            .obtain(text, 0, text.length, textPaint, width)
            .setAlignment(align)
            .setLineSpacing(profile.lineSpacingPx.toFloat(), 1.2f)
            .setIncludePad(true)
            .build()

        val height = staticLayout.height + 12

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Pure white background
        canvas.drawColor(Color.WHITE)
        canvas.translate(0f, 6f)
        staticLayout.draw(canvas)

        return processBitmapToEscPosRaster(bitmap)
    }

    /// Converts an input Bitmap image into ultra-sharp 1-bit monochrome ESC/POS raster byte array
    fun processBitmapToEscPosRaster(sourceBitmap: Bitmap): ByteArray {
        val targetWidth = profile.printableWidthDots
        val scale = targetWidth.toFloat() / sourceBitmap.width.toFloat()
        val targetHeight = (sourceBitmap.height * scale).toInt().coerceAtLeast(1)

        // Scale bitmap smoothly
        val scaledBitmap = Bitmap.createScaledBitmap(sourceBitmap, targetWidth, targetHeight, true)
        val width = scaledBitmap.width
        val height = scaledBitmap.height

        val widthInBytes = (width + 7) / 8
        val rasterData = ArrayList<Byte>()

        val pixels = IntArray(width * height)
        scaledBitmap.getPixels(pixels, 0, width, 0, 0, width, height)

        val threshold = profile.bitmapThreshold
        val contrastFactor = when (profile.darknessPreset) {
            DarknessPreset.EXTRA_DARK -> 1.7f
            DarknessPreset.DARK -> 1.35f
            DarknessPreset.NORMAL -> 1.0f
        }

        // Process line by line. Every BAND_HEIGHT rows start a new GS v 0
        // command so small printer buffers are not overrun.
        for (y in 0 until height) {
            if (y % BAND_HEIGHT == 0) {
                val bandRows = minOf(BAND_HEIGHT, height - y)
                rasterData.add(0x1D.toByte())
                rasterData.add(0x76.toByte())
                rasterData.add(0x30.toByte())
                rasterData.add(0x00.toByte()) // Normal mode
                rasterData.add((widthInBytes and 0xFF).toByte())
                rasterData.add(((widthInBytes shr 8) and 0xFF).toByte())
                rasterData.add((bandRows and 0xFF).toByte())
                rasterData.add(((bandRows shr 8) and 0xFF).toByte())
            }
            for (xByte in 0 until widthInBytes) {
                var byteVal = 0
                for (bit in 0 until 8) {
                    val x = xByte * 8 + bit
                    if (x < width) {
                        val pixel = pixels[y * width + x]
                        val r = (pixel shr 16) and 0xFF
                        val g = (pixel shr 8) and 0xFF
                        val b = pixel and 0xFF

                        // Grayscale Luminance calculation
                        var gray = (0.299f * r + 0.587f * g + 0.114f * b)

                        // Contrast Enhancement
                        gray = ((gray - 128f) * contrastFactor + 128f).coerceIn(0f, 255f)

                        // Thresholding: Gray < Threshold -> Black pixel (1)
                        if (gray < threshold) {
                            byteVal = byteVal or (0x80 shr bit)
                        }
                    }
                }
                rasterData.add(byteVal.toByte())
            }
        }

        return rasterData.toByteArray()
    }

    companion object {
        /** Rows per GS v 0 command. */
        const val BAND_HEIGHT = 128
    }
}
