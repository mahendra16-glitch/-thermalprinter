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
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
                val intent = PendingIntent.getBroadcast(
                    context,
                    0,
                    Intent("com.example.thermalprinter.USB_PERMISSION"),
                    flags
                )
                usbManager.requestPermission(targetDevice, intent)
                lastError = "USB permission requested from system."
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
            val transferred = conn.bulkTransfer(ep, bytes, bytes.size, 5000)
            if (transferred >= 0) {
                true
            } else {
                lastError = "Failed writing bytes to USB printer."
                false
            }
        } catch (e: Exception) {
            lastError = "USB write error: ${e.localizedMessage}"
            disconnect()
            false
        }
    }

    override fun getLastError(): String? = lastError
}
