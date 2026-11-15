package com.example.thermalprinter

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Finds nearby Bluetooth Classic devices and pairs them, for the "Find
 * nearby printers" screen. Discovery results are streamed on an
 * EventChannel; pairing is a method call that answers when Android reports
 * the device bonded (or not).
 *
 * On Android 12+ only BLUETOOTH_SCAN / BLUETOOTH_CONNECT are needed (the
 * manifest marks scanning "neverForLocation"); Android 11 and older also
 * need location permission, reported as "need_location".
 */
@SuppressLint("MissingPermission")
class BluetoothDiscovery(private val activity: Activity) : EventChannel.StreamHandler {

    private var sink: EventChannel.EventSink? = null
    private var receiver: BroadcastReceiver? = null

    private fun adapter(): BluetoothAdapter? =
        (activity.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?)?.adapter

    private fun granted(p: String) =
        activity.checkSelfPermission(p) == PackageManager.PERMISSION_GRANTED

    /** Null when ready, otherwise an error code for Dart. */
    private fun problem(): String? {
        val a = adapter() ?: return "unsupported"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!granted(Manifest.permission.BLUETOOTH_SCAN) ||
                !granted(Manifest.permission.BLUETOOTH_CONNECT)
            ) return "no_permission"
        } else if (!granted(Manifest.permission.ACCESS_FINE_LOCATION)) {
            return "need_location"
        }
        if (!a.isEnabled) return "bt_off"
        return null
    }

    private fun describe(d: BluetoothDevice, rssi: Int?): Map<String, Any?> = mapOf(
        "event" to "found",
        "name" to (d.name ?: ""),
        "address" to d.address,
        "printer" to (d.bluetoothClass?.majorDeviceClass == BluetoothClass.Device.Major.IMAGING),
        "major" to (d.bluetoothClass?.majorDeviceClass ?: -1),
        "bonded" to (d.bondState == BluetoothDevice.BOND_BONDED),
        "rssi" to rssi,
        // Only Bluetooth Classic (or dual) devices can be used.
        "classic" to (d.type != BluetoothDevice.DEVICE_TYPE_LE),
    )

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        val p = problem()
        if (p != null) {
            events.error(p, p, null)
            return
        }
        val a = adapter()!!
        val r = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    BluetoothDevice.ACTION_FOUND -> {
                        val d: BluetoothDevice? = if (Build.VERSION.SDK_INT >= 33) {
                            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                        }
                        val rssi = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, Short.MIN_VALUE)
                        if (d != null) {
                            sink?.success(describe(d, if (rssi == Short.MIN_VALUE) null else rssi.toInt()))
                        }
                    }
                    BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                        sink?.success(mapOf("event" to "finished"))
                    }
                }
            }
        }
        receiver = r
        val filter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
        }
        if (Build.VERSION.SDK_INT >= 33) {
            activity.registerReceiver(r, filter, Context.RECEIVER_EXPORTED)
        } else {
            activity.registerReceiver(r, filter)
        }
        if (a.isDiscovering) a.cancelDiscovery()
        if (!a.startDiscovery()) {
            events.error("scan_failed", "Android did not start the search.", null)
        }
    }

    override fun onCancel(arguments: Any?) {
        stop()
        sink = null
    }

    fun stop() {
        try {
            adapter()?.let { if (it.isDiscovering) it.cancelDiscovery() }
        } catch (_: SecurityException) {
        }
        receiver?.let {
            try {
                activity.unregisterReceiver(it)
            } catch (_: IllegalArgumentException) {
            }
        }
        receiver = null
    }

    /** Pairs [address]; answers true when bonded, false when refused. */
    fun pair(address: String, result: MethodChannel.Result) {
        val p = problem()
        if (p != null) {
            result.error(p, p, null)
            return
        }
        val a = adapter()!!
        val device = try {
            a.getRemoteDevice(address)
        } catch (e: IllegalArgumentException) {
            result.error("bad_address", "Not a valid Bluetooth address.", null)
            return
        }
        if (device.bondState == BluetoothDevice.BOND_BONDED) {
            result.success(true)
            return
        }
        if (a.isDiscovering) a.cancelDiscovery()
        var answered = false
        val r = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val d: BluetoothDevice? = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                }
                if (d?.address != address || answered) return
                val state = intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, BluetoothDevice.ERROR)
                val previous = intent.getIntExtra(
                    BluetoothDevice.EXTRA_PREVIOUS_BOND_STATE, BluetoothDevice.ERROR,
                )
                if (state == BluetoothDevice.BOND_BONDED) {
                    answered = true
                    result.success(true)
                } else if (state == BluetoothDevice.BOND_NONE &&
                    previous == BluetoothDevice.BOND_BONDING
                ) {
                    answered = true
                    result.success(false)
                } else {
                    return
                }
                try {
                    activity.unregisterReceiver(this)
                } catch (_: IllegalArgumentException) {
                }
            }
        }
        val filter = IntentFilter(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
        if (Build.VERSION.SDK_INT >= 33) {
            activity.registerReceiver(r, filter, Context.RECEIVER_EXPORTED)
        } else {
            activity.registerReceiver(r, filter)
        }
        if (!device.createBond()) {
            try {
                activity.unregisterReceiver(r)
            } catch (_: IllegalArgumentException) {
            }
            if (!answered) {
                answered = true
                result.error("pair_failed", "Android did not start pairing.", null)
            }
        }
    }
}
