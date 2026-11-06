package com.example.thermalprinter

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
import androidx.annotation.NonNull
import com.example.thermalprinter.calibration.CalibrationWizard
import com.example.thermalprinter.models.DarknessPreset
import com.example.thermalprinter.models.PaperWidth
import com.example.thermalprinter.models.PosOrder
import com.example.thermalprinter.models.PosOrderItem
import com.example.thermalprinter.models.PrinterProfile
import com.example.thermalprinter.models.PrinterRole
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val USB_CHANNEL = "com.example.thermalprinter/usb"
    private val ENGINE_CHANNEL = "com.example.thermalprinter/engine"
    private val ACTION_USB_PERMISSION = "com.example.thermalprinter.USB_PERMISSION"

    private var activeConnection: UsbDeviceConnection? = null
    private var activeEndpoint: UsbEndpoint? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Native USB Channel Handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USB_CHANNEL).setMethodCallHandler { call, result ->
            val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager

            when (call.method) {
                "getUsbDevices" -> {
                    try {
                        val deviceList = usbManager.deviceList
                        val list = mutableListOf<Map<String, Any>>()
                        for ((_, device) in deviceList) {
                            list.add(
                                mapOf(
                                    "deviceName" to device.deviceName,
                                    "vendorId" to device.vendorId,
                                    "productId" to device.productId,
                                    "deviceNameUser" to (device.productName ?: device.deviceName)
                                )
                            )
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        result.error("USB_ERROR", e.message, null)
                    }
                }
                "connectUsb" -> {
                    val vid = call.argument<Int>("vendorId")
                    val pid = call.argument<Int>("productId")
                    val targetName = call.argument<String>("deviceName")

                    try {
                        var targetDevice: UsbDevice? = null
                        for ((_, device) in usbManager.deviceList) {
                            if ((vid != null && pid != null && device.vendorId == vid && device.productId == pid) ||
                                (targetName != null && device.deviceName == targetName)
                            ) {
                                targetDevice = device
                                break
                            }
                        }

                        if (targetDevice == null && usbManager.deviceList.isNotEmpty()) {
                            targetDevice = usbManager.deviceList.values.first()
                        }

                        if (targetDevice == null) {
                            result.error("NO_DEVICE", "No USB printer detected.", null)
                            return@setMethodCallHandler
                        }

                        if (!usbManager.hasPermission(targetDevice)) {
                            val flag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
                            val permissionIntent = PendingIntent.getBroadcast(this, 0, Intent(ACTION_USB_PERMISSION), flag)
                            usbManager.requestPermission(targetDevice, permissionIntent)
                            result.error("PERMISSION_REQUIRED", "USB permission requested from system.", null)
                            return@setMethodCallHandler
                        }

                        var usbInterface: UsbInterface? = null
                        var endpointOut: UsbEndpoint? = null

                        for (i in 0 until targetDevice.interfaceCount) {
                            val iface = targetDevice.getInterface(i)
                            for (j in 0 until iface.endpointCount) {
                                val ep = iface.getEndpoint(j)
                                if (ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK &&
                                    ep.direction == UsbConstants.USB_DIR_OUT
                                ) {
                                    usbInterface = iface
                                    endpointOut = ep
                                    break
                                }
                            }
                            if (endpointOut != null) break
                        }

                        if (usbInterface == null || endpointOut == null) {
                            result.error("INTERFACE_ERROR", "Could not find bulk output endpoint on USB device.", null)
                            return@setMethodCallHandler
                        }

                        val connection = usbManager.openDevice(targetDevice)
                        if (connection == null || !connection.claimInterface(usbInterface, true)) {
                            result.error("CLAIM_ERROR", "Failed to open USB device interface.", null)
                            return@setMethodCallHandler
                        }

                        activeConnection = connection
                        activeEndpoint = endpointOut
                        result.success(true)

                    } catch (e: Exception) {
                        result.error("CONNECT_FAILED", e.message, null)
                    }
                }
                "sendRawBytes" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error("INVALID_DATA", "Byte payload is null.", null)
                        return@setMethodCallHandler
                    }

                    val conn = activeConnection
                    val ep = activeEndpoint

                    if (conn == null || ep == null) {
                        result.error("NOT_CONNECTED", "USB printer is not connected.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val transferred = conn.bulkTransfer(ep, bytes, bytes.size, 5000)
                        if (transferred >= 0) {
                            result.success(true)
                        } else {
                            result.error("TRANSFER_FAILED", "Failed writing bytes to USB printer.", null)
                        }
                    } catch (e: Exception) {
                        result.error("WRITE_ERROR", e.message, null)
                    }
                }
                "disconnectUsb" -> {
                    try {
                        activeConnection?.close()
                    } catch (_: Exception) {}
                    activeConnection = null
                    activeEndpoint = null
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 2. Native Engine & Calibration Channel Handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENGINE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "runCalibration" -> {
                    val profileMap = call.argument<Map<String, Any>>("profile")
                    val profile = parseProfile(profileMap)

                    Thread {
                        try {
                            val success = CalibrationWizard(this).printCalibrationSheet(profile)
                            runOnUiThread {
                                if (success) {
                                    result.success(true)
                                } else {
                                    result.error("CALIBRATION_FAILED", "Failed to print calibration sheet.", null)
                                }
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("CALIBRATION_ERROR", e.localizedMessage, null)
                            }
                        }
                    }.start()
                }
                "printNativeOrder" -> {
                    val profileMap = call.argument<Map<String, Any>>("profile")
                    val orderMap = call.argument<Map<String, Any>>("order")

                    val profile = parseProfile(profileMap)
                    val order = parseOrder(orderMap)

                    Thread {
                        try {
                            val manager = PrinterManager(this)
                            val success = manager.printOrder(order, profile)
                            runOnUiThread {
                                if (success) {
                                    result.success(true)
                                } else {
                                    result.error("PRINT_FAILED", profile.lastError ?: "Print failed", null)
                                }
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("PRINT_ERROR", e.localizedMessage, null)
                            }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun parseProfile(map: Map<String, Any>?): PrinterProfile {
        if (map == null) return PrinterProfile(id = "default", name = "Thermal Printer")

        val widthStr = map["paperWidth"] as? String ?: "MM80"
        val paperWidth = if (widthStr.contains("58")) PaperWidth.MM58 else PaperWidth.MM80

        val presetStr = map["darknessPreset"] as? String ?: "EXTRA_DARK"
        val darknessPreset = when (presetStr.uppercase()) {
            "NORMAL" -> DarknessPreset.NORMAL
            "DARK" -> DarknessPreset.DARK
            else -> DarknessPreset.EXTRA_DARK
        }

        val connStr = map["connectionType"] as? String ?: "TCP"
        val connType = when (connStr.uppercase()) {
            "BLUETOOTH" -> com.example.thermalprinter.models.ConnectionType.BLUETOOTH
            "USB" -> com.example.thermalprinter.models.ConnectionType.USB
            else -> com.example.thermalprinter.models.ConnectionType.TCP
        }

        return PrinterProfile(
            id = map["id"] as? String ?: "printer_1",
            name = map["name"] as? String ?: "Kitchen Printer",
            connectionType = connType,
            macAddress = map["macAddress"] as? String,
            vendorId = (map["vendorId"] as? Number)?.toInt(),
            productId = (map["productId"] as? Number)?.toInt(),
            deviceName = map["deviceName"] as? String,
            ipAddress = map["ipAddress"] as? String ?: "192.168.1.12",
            port = (map["port"] as? Number)?.toInt() ?: 9100,
            paperWidth = paperWidth,
            printableWidthDots = if (paperWidth == PaperWidth.MM58) 384 else 576,
            charsPerLine = if (paperWidth == PaperWidth.MM58) 32 else 48,
            role = PrinterRole.BILL,
            darknessPreset = darknessPreset,
            bitmapThreshold = (map["bitmapThreshold"] as? Number)?.toInt() ?: 150,
            fontWeightBold = true,
            lineSpacingPx = (map["lineSpacingPx"] as? Number)?.toInt() ?: 4,
            ditheringEnabled = map["ditheringEnabled"] as? Boolean ?: true,
            emojiSizePx = (map["emojiSizePx"] as? Number)?.toInt() ?: 36,
            kotFontSize = map["kotFontSize"] as? String ?: "LARGE"
        )
    }

    private fun parseOrder(map: Map<String, Any>?): PosOrder {
        if (map == null) return PosOrder(orderId = "1001", items = emptyList())

        val itemsList = mutableListOf<PosOrderItem>()
        val rawItems = map["items"] as? List<Map<String, Any>> ?: emptyList()

        for (itemMap in rawItems) {
            itemsList.add(
                PosOrderItem(
                    name = itemMap["name"] as? String ?: "Item",
                    qty = (itemMap["qty"] as? Number)?.toInt() ?: 1,
                    price = (itemMap["price"] as? Number)?.toDouble() ?: 0.0,
                    notes = itemMap["notes"] as? String
                )
            )
        }

        return PosOrder(
            orderId = map["orderId"] as? String ?: "1024",
            billNo = map["billNo"] as? String ?: map["orderId"] as? String ?: "1024",
            type = map["type"] as? String ?: "BILL",
            restaurantName = map["restaurantName"] as? String ?: "MYGENIE RESTAURANT",
            customerName = map["customerName"] as? String ?: "Rahul Sharma",
            customerPhone = map["customerPhone"] as? String ?: "9876543210",
            tableNumber = map["tableNumber"] as? String ?: "T-05",
            orderType = map["orderType"] as? String ?: "DINE-IN",
            items = itemsList,
            subtotal = (map["subtotal"] as? Number)?.toDouble() ?: 0.0,
            cgst = (map["cgst"] as? Number)?.toDouble() ?: 0.0,
            sgst = (map["sgst"] as? Number)?.toDouble() ?: 0.0,
            discount = (map["discount"] as? Number)?.toDouble() ?: 0.0,
            total = (map["total"] as? Number)?.toDouble() ?: 0.0,
            paymentMethod = map["paymentMethod"] as? String ?: "UPI",
            paymentStatus = map["paymentStatus"] as? String ?: "✓ PAID"
        )
    }
}
