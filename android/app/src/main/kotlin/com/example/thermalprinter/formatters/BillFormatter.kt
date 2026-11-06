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

class BillFormatter {

    fun formatBill(
        order: PosOrder,
        profile: PrinterProfile,
        template: ReceiptTemplate
    ): ByteArray {
        val encoder = EscPosEncoder(profile)
        val rasterEngine = ThermalRasterEngine(profile)
        val dateFormat = SimpleDateFormat("dd-MM-yyyy", Locale.getDefault())
        val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
        val dateStr = dateFormat.format(Date(order.timestamp))
        val timeStr = timeFormat.format(Date(order.timestamp))

        // Restaurant Header
        val nameToPrint = template.restaurantName.ifEmpty { order.restaurantName }
        if (UnicodeRenderer.containsComplexUnicode(nameToPrint)) {
            val raster = rasterEngine.renderTextToRasterBytes(
                text = nameToPrint,
                textSizeSp = 24f,
                isBold = true,
                align = Layout.Alignment.ALIGN_CENTER
            )
            encoder.appendRawBytes(raster)
        } else {
            encoder.alignCenter().bold(true).textSize(1, 1).text(nameToPrint).textSize(0, 0)
        }

        // Bill Title
        if (UnicodeRenderer.containsComplexUnicode(template.billTitle)) {
            val raster = rasterEngine.renderTextToRasterBytes(
                text = template.billTitle,
                textSizeSp = 20f,
                isBold = true,
                align = Layout.Alignment.ALIGN_CENTER
            )
            encoder.appendRawBytes(raster)
        } else {
            encoder.alignCenter().bold(true).text(template.billTitle)
        }

        if (template.address.isNotEmpty()) {
            encoder.alignCenter().bold(false).text(template.address)
        }
        if (template.phone.isNotEmpty()) {
            encoder.alignCenter().text("Phone: ${template.phone}")
        }
        if (template.showGstDetails && !template.gstin.isNullOrEmpty()) {
            encoder.alignCenter().text("GSTIN: ${template.gstin}")
        }

        encoder.divider()

        // Order Info
        encoder.alignLeft().text("Bill No: ${order.billNo}")
        encoder.text("Date: $dateStr     Time: $timeStr")

        if (template.showCustomerDetails && !order.customerName.isNullOrEmpty()) {
            val custText = "Customer: ${order.customerName}"
            if (UnicodeRenderer.containsComplexUnicode(custText)) {
                val raster = rasterEngine.renderTextToRasterBytes(custText, textSizeSp = 18f)
                encoder.appendRawBytes(raster)
            } else {
                encoder.text(custText)
            }
        }
        if (!order.customerPhone.isNullOrEmpty()) {
            encoder.text("Mobile: ${order.customerPhone}")
        }
        if (!order.tableNumber.isNullOrEmpty()) {
            encoder.text("Table: ${order.tableNumber}     Type: ${order.orderType}")
        }
        encoder.divider()

        // Items Header
        encoder.row("ITEM", "QTY", "PRICE", flex1 = 3, flex2 = 1, flex3 = 2)
        encoder.divider()

        // Items
        for (item in order.items) {
            val itemLine = "${item.name} x${item.qty} ₹${String.format("%.2f", item.price * item.qty)}"
            if (UnicodeRenderer.containsComplexUnicode(item.name) || UnicodeRenderer.containsComplexUnicode(itemLine)) {
                val raster = rasterEngine.renderTextToRasterBytes(
                    text = "${item.name}  x${item.qty}  ₹${String.format("%.2f", item.price * item.qty)}",
                    textSizeSp = 18f
                )
                encoder.appendRawBytes(raster)
            } else {
                encoder.row(
                    item.name,
                    item.qty.toString(),
                    String.format("%.2f", item.price * item.qty),
                    flex1 = 3, flex2 = 1, flex3 = 2
                )
            }
        }
        encoder.divider()

        // Totals
        encoder.row("Subtotal:", "", String.format("%.2f", order.subtotal), flex1 = 2, flex2 = 1, flex3 = 2)
        if (order.cgst > 0) {
            encoder.row("CGST:", "", String.format("%.2f", order.cgst), flex1 = 2, flex2 = 1, flex3 = 2)
        }
        if (order.sgst > 0) {
            encoder.row("SGST:", "", String.format("%.2f", order.sgst), flex1 = 2, flex2 = 1, flex3 = 2)
        }
        if (order.discount > 0) {
            encoder.row("Discount:", "", "-${String.format("%.2f", order.discount)}", flex1 = 2, flex2 = 1, flex3 = 2)
        }
        encoder.divider()

        // Grand Total Line
        val totalText = "TOTAL: ₹${String.format("%.2f", order.total)}"
        val rasterTotal = rasterEngine.renderTextToRasterBytes(
            text = totalText,
            textSizeSp = 22f,
            isBold = true,
            align = Layout.Alignment.ALIGN_OPPOSITE
        )
        encoder.appendRawBytes(rasterTotal)
        encoder.divider()

        // Payment Info
        encoder.text("Payment: ${order.paymentMethod}")
        val statusRaster = rasterEngine.renderTextToRasterBytes(
            text = "Status: ${order.paymentStatus}",
            textSizeSp = 20f,
            isBold = true
        )
        encoder.appendRawBytes(statusRaster)
        encoder.divider()

        // Footer Message
        val footerRaster = rasterEngine.renderTextToRasterBytes(
            text = template.footerMessage,
            textSizeSp = 18f,
            align = Layout.Alignment.ALIGN_CENTER
        )
        encoder.appendRawBytes(footerRaster)

        encoder.cut()
        return encoder.build()
    }
}
