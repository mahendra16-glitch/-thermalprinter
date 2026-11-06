package com.example.thermalprinter.models

enum class PrintJobStatus { PENDING, PRINTING, PRINTED, FAILED }

data class PrintJob(
    val id: String,
    val orderId: String,
    val printType: String = "BILL",
    val targetRole: PrinterRole = PrinterRole.BILL,
    val order: PosOrder,
    var status: PrintJobStatus = PrintJobStatus.PENDING,
    var retryCount: Int = 0,
    var errorMessage: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    var processedAt: Long? = null
)
