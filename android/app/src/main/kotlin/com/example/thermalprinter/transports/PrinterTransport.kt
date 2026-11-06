package com.example.thermalprinter.transports

interface PrinterTransport {
    fun connect(): Boolean
    fun disconnect()
    fun isConnected(): Boolean
    fun sendBytes(bytes: ByteArray): Boolean
    fun getLastError(): String?
}
