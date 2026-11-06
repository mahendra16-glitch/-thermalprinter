package com.example.thermalprinter.models

/**
 * Business details printed on native bills and KOTs. Everything defaults to
 * empty: nothing (in particular no GSTIN or FSSAI number) is printed unless
 * the business entered it.
 */
data class ReceiptTemplate(
    val restaurantName: String = "",
    val billTitle: String = "BILL",
    val kotTitle: String = "",
    val address: String = "",
    val phone: String = "",
    val gstin: String? = null,
    val fssai: String? = null,
    val headerMessage: String = "",
    val footerMessage: String = "",
    val showLogo: Boolean = false,
    val showQrCode: Boolean = false,
    val showCustomerDetails: Boolean = true,
    val showGstDetails: Boolean = true
)
