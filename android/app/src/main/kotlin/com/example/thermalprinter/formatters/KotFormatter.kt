package com.example.thermalprinter.formatters

import android.text.Layout
import com.example.thermalprinter.engine.EscPosEncoder
import com.example.thermalprinter.engine.ThermalRasterEngine
import com.example.thermalprinter.engine.UnicodeRenderer
import com.example.thermalprinter.models.PosOrder
import com.example.thermalprinter.models.PrinterProfile
import com.example.thermalprinter.models.ReceiptTemplate
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class KotFormatter {

    fun formatKot(
        order: PosOrder,
        profile: PrinterProfile,
        template: ReceiptTemplate
    ): ByteArray {
        val encoder = EscPosEncoder(profile)
        val rasterEngine = ThermalRasterEngine(profile)
        val timeFormat = SimpleDateFormat("hh:mm a", Locale.getDefault())
        val timeStr = timeFormat.format(Date(order.timestamp))

        // Large Header for Kitchen
        val kotHeader = if (template.kotTitle.isEmpty()) "KOT" else "KOT\n${template.kotTitle}"
        val headerRaster = rasterEngine.renderTextToRasterBytes(
            text = kotHeader,
            textSizeSp = 28f,
            isBold = true,
            align = Layout.Alignment.ALIGN_CENTER
        )
        encoder.appendRawBytes(headerRaster)
        encoder.divider()

        // Meta Info
        encoder.text("KOT #: ${order.billNo}")
        encoder.text("Order #: ${order.orderId}")
        if (!order.tableNumber.isNullOrEmpty()) {
            encoder.bold(true).text("TABLE: ${order.tableNumber}").bold(false)
        }
        encoder.text("Time: $timeStr")
        encoder.divider()

        // Items with Large Quantities & Modifications
        for (item in order.items) {
            val itemLine = "${item.qty} x ${item.name}"
            
            // Large Bold text for KOT Items
            val itemRaster = rasterEngine.renderTextToRasterBytes(
                text = itemLine,
                textSizeSp = when (profile.kotFontSize) {
                    "EXTRA_LARGE" -> 26f
                    "LARGE" -> 22f
                    else -> 18f
                },
                isBold = true
            )
            encoder.appendRawBytes(itemRaster)

            if (!item.notes.isNullOrEmpty()) {
                val notesRaster = rasterEngine.renderTextToRasterBytes(
                    text = "    - ${item.notes}",
                    textSizeSp = 18f
                )
                encoder.appendRawBytes(notesRaster)
            }

            for (addOn in item.addOns) {
                val addOnRaster = rasterEngine.renderTextToRasterBytes(
                    text = "    + $addOn",
                    textSizeSp = 18f
                )
                encoder.appendRawBytes(addOnRaster)
            }
        }

        encoder.divider()

        if (!order.specialNotes.isNullOrEmpty()) {
            val notesHeaderRaster = rasterEngine.renderTextToRasterBytes(
                text = "SPECIAL INSTRUCTIONS:\n${order.specialNotes}",
                textSizeSp = 20f,
                isBold = true
            )
            encoder.appendRawBytes(notesHeaderRaster)
            encoder.divider()
        }

        if (!order.waiterName.isNullOrEmpty()) {
            encoder.text("Waiter: ${order.waiterName}")
            encoder.divider()
        }

        encoder.cut()
        return encoder.build()
    }
}
