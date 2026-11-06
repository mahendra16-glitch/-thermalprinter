package com.example.thermalprinter.transports

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import com.example.thermalprinter.models.PrinterProfile
import java.io.OutputStream
import java.util.UUID

class BluetoothPrinterTransport(private val profile: PrinterProfile) : PrinterTransport {
    private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private var socket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private var lastError: String? = null

    override fun connect(): Boolean {
        val mac = profile.macAddress ?: run {
            lastError = "Bluetooth MAC address is required."
            return false
        }

        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter() ?: run {
            lastError = "Bluetooth is not supported on this device."
            return false
        }

        if (!bluetoothAdapter.isEnabled) {
            lastError = "Bluetooth is turned off."
            return false
        }

        return try {
            disconnect()
            val device: BluetoothDevice = bluetoothAdapter.getRemoteDevice(mac)
            bluetoothAdapter.cancelDiscovery()

            val newSocket = device.createRfcommSocketToServiceRecord(SPP_UUID)
            newSocket.connect()

            socket = newSocket
            outputStream = newSocket.outputStream
            lastError = null
            true
        } catch (e: Exception) {
            lastError = "Bluetooth connection failed: ${e.localizedMessage}"
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
        return socket?.isConnected == true
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
            lastError = "Bluetooth write error: ${e.localizedMessage}"
            disconnect()
            false
        }
    }

    override fun getLastError(): String? = lastError
}
