package com.example.thermalprinter

import android.Manifest
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import androidx.annotation.NonNull
import com.example.thermalprinter.calibration.CalibrationWizard
import com.example.thermalprinter.models.DarknessPreset
import com.example.thermalprinter.models.PaperWidth
import com.example.thermalprinter.models.PosOrder
import com.example.thermalprinter.models.PosOrderItem
import com.example.thermalprinter.models.PrinterProfile
import com.example.thermalprinter.models.PrinterRole
import com.example.thermalprinter.models.ReceiptTemplate
import com.example.thermalprinter.transports.UsbPrinterTransport
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val USB_CHANNEL = "com.example.thermalprinter/usb"
    private val ENGINE_CHANNEL = "com.example.thermalprinter/engine"
    private val BT_CHANNEL = "com.example.thermalprinter/bluetooth"
    private val BT_SCAN_CHANNEL = "com.example.thermalprinter/bluetooth_scan"
    private var discovery: BluetoothDiscovery? = null

    private var activeConnection: UsbDeviceConnection? = null
    private var activeEndpoint: UsbEndpoint? = null

    private fun bluetoothDiscovery(): BluetoothDiscovery =
        discovery ?: BluetoothDiscovery(this).also { discovery = it }

    override fun onDestroy() {
        discovery?.stop()
        super.onDestroy()
    }

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
                            usbManager.requestPermission(
                                targetDevice,
                                UsbPrinterTransport.permissionIntent(this)
                            )
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
                        val error = UsbPrinterTransport.writeAll(conn, ep, bytes)
                        if (error == null) {
                            result.success(true)
                        } else {
                            result.error("TRANSFER_FAILED", error, null)
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

        // 1b. Paired Bluetooth devices. Needs only BLUETOOTH_CONNECT on
        // Android 12+ (the blue_thermal_printer plugin also demands location
        // there and never answers if it has to ask for it).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBondedDevices" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                            checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) !=
                            PackageManager.PERMISSION_GRANTED
                        ) {
                            result.error("no_permission", "Nearby devices permission is not allowed.", null)
                            return@setMethodCallHandler
                        }
                        val manager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
                        val adapter = manager?.adapter
                        if (adapter == null) {
                            result.error("unsupported", "This device has no Bluetooth.", null)
                            return@setMethodCallHandler
                        }
                        if (!adapter.isEnabled) {
                            result.error("bt_off", "Bluetooth is turned off.", null)
                            return@setMethodCallHandler
                        }
                        val list = adapter.bondedDevices.map { d ->
                            mapOf(
                                "name" to (d.name ?: ""),
                                "address" to d.address,
                                "printer" to (d.bluetoothClass?.majorDeviceClass ==
                                    BluetoothClass.Device.Major.IMAGING),
                                "major" to (d.bluetoothClass?.majorDeviceClass ?: -1)
                            )
                        }
                        result.success(list)
                    } catch (e: SecurityException) {
                        result.error("no_permission", e.message, null)
                    } catch (e: Exception) {
                        result.error("bt_error", e.message, null)
                    }
                }
                "pair" -> {
                    val address = call.argument<String>("address")
                    if (address == null) {
                        result.error("bad_address", "No address given.", null)
                    } else {
                        bluetoothDiscovery().pair(address, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, BT_SCAN_CHANNEL)
            .setStreamHandler(bluetoothDiscovery())

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
                    val template = parseTemplate(call.argument<Map<String, Any>>("template"))

                    Thread {
                        try {
                            val manager = PrinterManager(this)
                            val success = manager.printOrder(order, profile, template)
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
            name = map["name"] as? String ?: "Printer",
            connectionType = connType,
            macAddress = map["macAddress"] as? String,
            vendorId = (map["vendorId"] as? Number)?.toInt(),
            productId = (map["productId"] as? Number)?.toInt(),
            deviceName = map["deviceName"] as? String,
            ipAddress = map["ipAddress"] as? String,
            port = (map["port"] as? Number)?.toInt() ?: 9100,
            paperWidth = paperWidth,
            printableWidthDots = (map["printableDots"] as? Number)?.toInt()
                ?: if (paperWidth == PaperWidth.MM58) 384 else 576,
            charsPerLine = (map["charsPerLine"] as? Number)?.toInt()
                ?: if (paperWidth == PaperWidth.MM58) 32 else 48,
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

    /** Business details from the app's business profile. */
    private fun parseTemplate(map: Map<String, Any>?): ReceiptTemplate? {
        if (map == null) return null
        return ReceiptTemplate(
            restaurantName = map["name"] as? String ?: "",
            address = map["address"] as? String ?: "",
            phone = map["phone"] as? String ?: "",
            gstin = (map["gstin"] as? String)?.ifBlank { null },
            fssai = (map["fssai"] as? String)?.ifBlank { null },
            footerMessage = map["billFooter"] as? String ?: ""
        )
    }

    private fun parseOrder(map: Map<String, Any>?): PosOrder {
        if (map == null) return PosOrder(orderId = "", items = emptyList())

        val itemsList = mutableListOf<PosOrderItem>()
        val rawItems = map["items"] as? List<Map<String, Any>> ?: emptyList()

        for (itemMap in rawItems) {
            itemsList.add(
                PosOrderItem(
                    name = itemMap["name"] as? String ?: "Item",
                    qty = (itemMap["qty"] as? Number)?.toInt() ?: 1,
                    price = (itemMap["price"] as? Number)?.toDouble() ?: 0.0,
                    notes = itemMap["notes"] as? String,
                    addOns = (itemMap["addOns"] as? List<*>)?.map { it.toString() } ?: emptyList()
                )
            )
        }

        // No sample defaults: a missing field is left empty and not printed.
        return PosOrder(
            orderId = map["orderId"] as? String ?: "",
            billNo = map["billNo"] as? String ?: map["orderId"] as? String ?: "",
            type = map["type"] as? String ?: "BILL",
            restaurantName = map["restaurantName"] as? String ?: "",
            customerName = map["customerName"] as? String,
            customerPhone = map["customerPhone"] as? String,
            tableNumber = map["tableNumber"] as? String,
            orderType = map["orderType"] as? String ?: "",
            waiterName = map["waiterName"] as? String,
            specialNotes = map["specialNotes"] as? String,
            items = itemsList,
            subtotal = (map["subtotal"] as? Number)?.toDouble() ?: 0.0,
            cgst = (map["cgst"] as? Number)?.toDouble() ?: 0.0,
            sgst = (map["sgst"] as? Number)?.toDouble() ?: 0.0,
            discount = (map["discount"] as? Number)?.toDouble() ?: 0.0,
            total = (map["total"] as? Number)?.toDouble() ?: 0.0,
            paymentMethod = map["paymentMethod"] as? String ?: "",
            paymentStatus = map["paymentStatus"] as? String ?: ""
        )
    }
}
