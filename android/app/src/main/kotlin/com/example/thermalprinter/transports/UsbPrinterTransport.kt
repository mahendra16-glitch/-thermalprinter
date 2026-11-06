package com.example.thermalprinter.transports

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import com.example.thermalprinter.models.PrinterProfile

class UsbPrinterTransport(
    private val context: Context,
    private val profile: PrinterProfile
) : PrinterTransport {

    private var connection: UsbDeviceConnection? = null
    private var endpointOut: UsbEndpoint? = null
    private var lastError: String? = null

    override fun connect(): Boolean {
        val usbManager = context.getSystemService(Context.USB_SERVICE) as? UsbManager ?: run {
            lastError = "UsbManager service unavailable."
            return false
        }

        try {
            var targetDevice: UsbDevice? = null
            val deviceList = usbManager.deviceList

            for ((_, device) in deviceList) {
                if ((profile.vendorId != null && profile.productId != null &&
                            device.vendorId == profile.vendorId && device.productId == profile.productId) ||
                    (profile.deviceName != null && device.deviceName == profile.deviceName)
                ) {
                    targetDevice = device
                    break
                }
            }

            if (targetDevice == null && deviceList.isNotEmpty()) {
                targetDevice = deviceList.values.first()
            }

            if (targetDevice == null) {
                lastError = "No USB printer detected."
                return false
            }

            if (!usbManager.hasPermission(targetDevice)) {
                usbManager.requestPermission(targetDevice, permissionIntent(context))
                lastError = "USB permission requested. Tap Allow on the phone, then retry."
                return false
            }

            var targetInterface: UsbInterface? = null
            var targetEndpoint: UsbEndpoint? = null

            for (i in 0 until targetDevice.interfaceCount) {
                val iface = targetDevice.getInterface(i)
                for (j in 0 until iface.endpointCount) {
                    val ep = iface.getEndpoint(j)
                    if (ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK &&
                        ep.direction == UsbConstants.USB_DIR_OUT
                    ) {
                        targetInterface = iface
                        targetEndpoint = ep
                        break
                    }
                }
                if (targetEndpoint != null) break
            }

            if (targetInterface == null || targetEndpoint == null) {
                lastError = "Could not find bulk output endpoint on USB device."
                return false
            }

            val conn = usbManager.openDevice(targetDevice) ?: run {
                lastError = "Failed to open USB device."
                return false
            }

            if (!conn.claimInterface(targetInterface, true)) {
                lastError = "Could not claim USB interface."
                conn.close()
                return false
            }

            connection = conn
            endpointOut = targetEndpoint
            lastError = null
            return true

        } catch (e: Exception) {
            lastError = "USB Error: ${e.localizedMessage}"
            disconnect()
            return false
        }
    }

    override fun disconnect() {
        try {
            connection?.close()
        } catch (_: Exception) {}
        connection = null
        endpointOut = null
    }

    override fun isConnected(): Boolean {
        return connection != null && endpointOut != null
    }

    override fun sendBytes(bytes: ByteArray): Boolean {
        if (!isConnected()) {
            if (!connect()) return false
        }

        val conn = connection
        val ep = endpointOut

        if (conn == null || ep == null) {
            lastError = "USB printer disconnected."
            return false
        }

        return try {
            val error = writeAll(conn, ep, bytes)
            if (error == null) {
                true
            } else {
                lastError = error
                false
            }
        } catch (e: Exception) {
            lastError = "USB write error: ${e.localizedMessage}"
            disconnect()
            false
        }
    }

    override fun getLastError(): String? = lastError

    companion object {
        const val ACTION_USB_PERMISSION = "com.example.thermalprinter.USB_PERMISSION"

        /** Bytes per bulk transfer; many printers and hosts cap at 16 KB. */
        private const val CHUNK_SIZE = 16 * 1024

        /**
         * The system adds the permission result to this intent, so on
         * Android 12+ it must be mutable; an explicit package keeps it safe
         * (Android 14 rejects mutable implicit intents).
         */
        fun permissionIntent(context: Context): PendingIntent {
            val intent = Intent(ACTION_USB_PERMISSION).setPackage(context.packageName)
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            return PendingIntent.getBroadcast(context, 0, intent, flags)
        }

        /**
         * Writes every byte in chunks and checks each chunk was fully
         * accepted. Returns null on success, or an error message. A short
         * write is a failure: it would otherwise print a truncated ticket
         * while reporting success.
         */
        fun writeAll(conn: UsbDeviceConnection, ep: UsbEndpoint, bytes: ByteArray): String? {
            var offset = 0
            while (offset < bytes.size) {
                val len = minOf(CHUNK_SIZE, bytes.size - offset)
                val sent = conn.bulkTransfer(ep, bytes, offset, len, 5000)
                if (sent < 0) return "USB write failed after $offset of ${bytes.size} bytes."
                if (sent == 0) return "USB printer accepted no data after $offset of ${bytes.size} bytes."
                offset += sent
            }
            return null
        }
    }
}
