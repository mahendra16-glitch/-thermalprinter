package com.example.thermalprinter.transports

import com.example.thermalprinter.models.PrinterProfile
import java.io.OutputStream
import java.net.InetSocketAddress
import java.net.Socket

class TcpPrinterTransport(private val profile: PrinterProfile) : PrinterTransport {
    private var socket: Socket? = null
    private var outputStream: OutputStream? = null
    private var lastError: String? = null

    override fun connect(): Boolean {
        val ip = profile.ipAddress ?: run {
            lastError = "Printer IP address is required."
            return false
        }
        val port = profile.port

        return try {
            disconnect()
            val newSocket = Socket()
            newSocket.connect(InetSocketAddress(ip, port), 5000)
            socket = newSocket
            outputStream = newSocket.getOutputStream()
            lastError = null
            true
        } catch (e: Exception) {
            lastError = "Unable to connect to $ip:$port (${e.localizedMessage})"
            disconnect()
            false
        }
    }

    override fun disconnect() {
        try {
            outputStream?.flush()
            outputStream?.close()
            socket?.close()
        } catch (_: Exception) {}
        outputStream = null
        socket = null
    }

    override fun isConnected(): Boolean {
        return socket?.isConnected == true && socket?.isClosed == false
    }

    override fun sendBytes(bytes: ByteArray): Boolean {
        if (!isConnected()) {
            if (!connect()) return false
        }

        return try {
            outputStream?.write(bytes)
            outputStream?.flush()
            true
        } catch (e: Exception) {
            lastError = "TCP send error: ${e.localizedMessage}"
            disconnect()
            false
        }
    }

    override fun getLastError(): String? = lastError
}
