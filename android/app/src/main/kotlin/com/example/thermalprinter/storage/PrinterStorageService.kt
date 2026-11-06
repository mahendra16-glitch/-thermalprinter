package com.example.thermalprinter.storage

import android.content.Context
import android.content.SharedPreferences
import com.example.thermalprinter.models.PrinterProfile
import com.example.thermalprinter.models.ReceiptTemplate
import org.json.JSONArray
import org.json.JSONObject

class PrinterStorageService(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("thermal_printer_prefs_v2", Context.MODE_PRIVATE)

    companion object {
        private const val KEY_PRINTERS = "saved_printers_list_v2"
        private const val KEY_TEMPLATE = "saved_receipt_template_v2"
    }

    // --- Saved Printer Profiles ---

    fun getSavedProfiles(): List<PrinterProfile> {
        val raw = prefs.getString(KEY_PRINTERS, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            val list = mutableListOf<PrinterProfile>()
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                list.add(profileFromJson(obj))
            }
            list
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun saveProfile(profile: PrinterProfile) {
        val list = getSavedProfiles().toMutableList()
        val index = list.indexOfFirst { it.id == profile.id }
        if (index >= 0) {
            list[index] = profile
        } else {
            list.add(profile)
        }
        saveProfileList(list)
    }

    fun deleteProfile(id: String) {
        val list = getSavedProfiles().toMutableList()
        list.removeAll { it.id == id }
        saveProfileList(list)
    }

    private fun saveProfileList(list: List<PrinterProfile>) {
        val array = JSONArray()
        for (p in list) {
            array.put(profileToJson(p))
        }
        prefs.edit().putString(KEY_PRINTERS, array.toString()).apply()
    }

    // --- Receipt Template Settings ---

    fun getReceiptTemplate(): ReceiptTemplate {
        val raw = prefs.getString(KEY_TEMPLATE, null) ?: return ReceiptTemplate()
        return try {
            val obj = JSONObject(raw)
            ReceiptTemplate(
                restaurantName = obj.optString("restaurantName", ""),
                billTitle = obj.optString("billTitle", "BILL"),
                kotTitle = obj.optString("kotTitle", ""),
                address = obj.optString("address", ""),
                phone = obj.optString("phone", ""),
                gstin = obj.optString("gstin", "").ifBlank { null },
                fssai = obj.optString("fssai", "").ifBlank { null },
                headerMessage = obj.optString("headerMessage", ""),
                footerMessage = obj.optString("footerMessage", ""),
                showLogo = obj.optBoolean("showLogo", false),
                showQrCode = obj.optBoolean("showQrCode", false),
                showCustomerDetails = obj.optBoolean("showCustomerDetails", true),
                showGstDetails = obj.optBoolean("showGstDetails", true)
            )
        } catch (e: Exception) {
            ReceiptTemplate()
        }
    }

    fun saveReceiptTemplate(template: ReceiptTemplate) {
        val obj = JSONObject().apply {
            put("restaurantName", template.restaurantName)
            put("billTitle", template.billTitle)
            put("kotTitle", template.kotTitle)
            put("address", template.address)
            put("phone", template.phone)
            put("gstin", template.gstin)
            put("fssai", template.fssai)
            put("headerMessage", template.headerMessage)
            put("footerMessage", template.footerMessage)
            put("showLogo", template.showLogo)
            put("showQrCode", template.showQrCode)
            put("showCustomerDetails", template.showCustomerDetails)
            put("showGstDetails", template.showGstDetails)
        }
        prefs.edit().putString(KEY_TEMPLATE, obj.toString()).apply()
    }

    // --- JSON Conversion Helpers ---

    private fun profileToJson(p: PrinterProfile): JSONObject {
        return JSONObject().apply {
            put("id", p.id)
            put("name", p.name)
            put("connectionType", p.connectionType.name)
            put("macAddress", p.macAddress)
            put("vendorId", p.vendorId)
            put("productId", p.productId)
            put("deviceName", p.deviceName)
            put("ipAddress", p.ipAddress)
            put("port", p.port)
            put("paperWidth", p.paperWidth.name)
            put("printableWidthDots", p.printableWidthDots)
            put("charsPerLine", p.charsPerLine)
            put("role", p.role.name)
            put("darknessPreset", p.darknessPreset.name)
            put("bitmapThreshold", p.bitmapThreshold)
            put("contrastMultiplier", p.contrastMultiplier)
            put("fontWeightBold", p.fontWeightBold)
            put("lineSpacingPx", p.lineSpacingPx)
            put("ditheringEnabled", p.ditheringEnabled)
            put("emojiSizePx", p.emojiSizePx)
            put("kotFontSize", p.kotFontSize)
        }
    }

    private fun profileFromJson(obj: JSONObject): PrinterProfile {
        return PrinterProfile(
            id = obj.getString("id"),
            name = obj.getString("name"),
            connectionType = com.example.thermalprinter.models.ConnectionType.valueOf(
                obj.optString("connectionType", "TCP")
            ),
            macAddress = obj.optString("macAddress", null),
            vendorId = if (obj.has("vendorId")) obj.getInt("vendorId") else null,
            productId = if (obj.has("productId")) obj.getInt("productId") else null,
            deviceName = obj.optString("deviceName", null),
            ipAddress = obj.optString("ipAddress", "").ifBlank { null },
            port = obj.optInt("port", 9100),
            paperWidth = com.example.thermalprinter.models.PaperWidth.valueOf(
                obj.optString("paperWidth", "MM80")
            ),
            printableWidthDots = obj.optInt("printableWidthDots", 576),
            charsPerLine = obj.optInt("charsPerLine", 48),
            role = com.example.thermalprinter.models.PrinterRole.valueOf(
                obj.optString("role", "BILL")
            ),
            darknessPreset = com.example.thermalprinter.models.DarknessPreset.valueOf(
                obj.optString("darknessPreset", "EXTRA_DARK")
            ),
            bitmapThreshold = obj.optInt("bitmapThreshold", 150),
            contrastMultiplier = obj.optDouble("contrastMultiplier", 1.6).toFloat(),
            fontWeightBold = obj.optBoolean("fontWeightBold", true),
            lineSpacingPx = obj.optInt("lineSpacingPx", 4),
            ditheringEnabled = obj.optBoolean("ditheringEnabled", true),
            emojiSizePx = obj.optInt("emojiSizePx", 36),
            kotFontSize = obj.optString("kotFontSize", "LARGE")
        )
    }
}
