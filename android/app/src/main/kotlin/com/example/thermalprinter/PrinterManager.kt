package com.example.thermalprinter

import android.content.Context
import com.example.thermalprinter.formatters.BillFormatter
import com.example.thermalprinter.formatters.KotFormatter
import com.example.thermalprinter.models.ConnectionType
import com.example.thermalprinter.models.PosOrder
import com.example.thermalprinter.models.PrinterProfile
import com.example.thermalprinter.models.ReceiptTemplate
import com.example.thermalprinter.storage.PrinterStorageService
import com.example.thermalprinter.transports.BluetoothPrinterTransport
import com.example.thermalprinter.transports.PrinterTransport
import com.example.thermalprinter.transports.TcpPrinterTransport
import com.example.thermalprinter.transports.UsbPrinterTransport

class PrinterManager(private val context: Context) {
    private val storage = PrinterStorageService(context)
    private val billFormatter = BillFormatter()
    private val kotFormatter = KotFormatter()

    fun getTransport(profile: PrinterProfile): PrinterTransport {
        return when (profile.connectionType) {
            ConnectionType.BLUETOOTH -> BluetoothPrinterTransport(profile)
            ConnectionType.USB -> UsbPrinterTransport(context, profile)
            ConnectionType.TCP -> TcpPrinterTransport(profile)
        }
    }

    /** [templateOverride] comes from the app's business profile. */
    fun printOrder(
        order: PosOrder,
        profile: PrinterProfile,
        templateOverride: ReceiptTemplate? = null
    ): Boolean {
        val template = templateOverride ?: storage.getReceiptTemplate()
        val bytes = if (order.type.equals("KOT", ignoreCase = true)) {
            kotFormatter.formatKot(order, profile, template)
        } else {
            billFormatter.formatBill(order, profile, template)
        }

        val transport = getTransport(profile)
        try {
            val success = transport.sendBytes(bytes)
            if (success) {
                profile.isConnected = true
                profile.lastConnectedTime = System.currentTimeMillis()
                profile.lastError = null
            } else {
                profile.isConnected = false
                profile.lastError = transport.getLastError() ?: "Failed sending print bytes."
            }
            storage.saveProfile(profile)
            return success
        } finally {
            transport.disconnect()
        }
    }

    fun testConnection(profile: PrinterProfile): Pair<Boolean, String?> {
        val transport = getTransport(profile)
        try {
            val connected = transport.connect()
            val error = transport.getLastError()
            return Pair(connected, error)
        } finally {
            transport.disconnect()
        }
    }
}
