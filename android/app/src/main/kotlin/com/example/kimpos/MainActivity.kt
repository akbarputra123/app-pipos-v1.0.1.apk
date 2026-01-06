package com.example.kimpos

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.*
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "usb_printer"
    private val ACTION_USB_PERMISSION = "com.example.kimpos.USB_PERMISSION"
    private val TAG = "USB_PRINTER"

    private var usbReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val usbManager = getSystemService(USB_SERVICE) as UsbManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // =================================================
                    // REQUEST USB PERMISSION
                    // =================================================
                    "requestUsbPermission" -> {
                        val device = usbManager.deviceList.values.firstOrNull()
                        if (device == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        if (usbManager.hasPermission(device)) {
                            result.success(true)
                            return@setMethodCallHandler
                        }

                        val intent = PendingIntent.getBroadcast(
                            this,
                            0,
                            Intent(ACTION_USB_PERMISSION),
                            PendingIntent.FLAG_IMMUTABLE
                        )

                        usbReceiver = object : BroadcastReceiver() {
                            override fun onReceive(context: Context?, intent: Intent?) {
                                if (intent?.action == ACTION_USB_PERMISSION) {
                                    val granted = intent.getBooleanExtra(
                                        UsbManager.EXTRA_PERMISSION_GRANTED,
                                        false
                                    )
                                    Log.d(TAG, "USB permission granted: $granted")
                                }
                            }
                        }

                        registerReceiver(
                            usbReceiver,
                            IntentFilter(ACTION_USB_PERMISSION),
                            Context.RECEIVER_NOT_EXPORTED
                        )

                        usbManager.requestPermission(device, intent)
                        result.success(false)
                    }

                    // =================================================
                    // LIST USB DEVICES
                    // =================================================
                    "getUsbDevices" -> {
                        result.success(
                            usbManager.deviceList.values.map {
                                "${it.deviceName}|VID:${it.vendorId}|PID:${it.productId}"
                            }
                        )
                    }

                    // =================================================
                    // PRINT BARCODE (TSPL - LABEL)
                    // =================================================
                    "printBarcodeWithName" -> {
                        val name = call.argument<String>("name") ?: ""
                        val barcode = call.argument<String>("barcode") ?: ""
                        val deviceName = call.argument<String>("deviceName") ?: ""

                        val device = usbManager.deviceList.values.firstOrNull {
                            deviceName.startsWith(it.deviceName)
                        }

                        if (device == null || !usbManager.hasPermission(device)) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        Thread {
                            val success = printTsplLabel(device, name, barcode)
                            Log.d(TAG, "TSPL Print success: $success")
                        }.start()

                        result.success(true)
                    }

                    // =================================================
                    // PRINT RECEIPT (ESC/POS - STRUK)
                    // =================================================
                    "printReceipt" -> {
                        val text = call.argument<String>("text") ?: ""
                        val deviceName = call.argument<String>("deviceName") ?: ""

                        val device = usbManager.deviceList.values.firstOrNull {
                            deviceName.startsWith(it.deviceName)
                        }

                        if (device == null || !usbManager.hasPermission(device)) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        Thread {
                            val success = printEscPos(device, text)
                            Log.d(TAG, "ESC/POS Print success: $success")
                        }.start()

                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        usbReceiver?.let { unregisterReceiver(it) }
        usbReceiver = null
    }

    // =================================================
    // TSPL PRINT (BARCODE / LABEL)
    // =================================================
    private fun printTsplLabel(
        device: UsbDevice,
        name: String,
        barcode: String
    ): Boolean {
        return try {
            val usbManager = getSystemService(USB_SERVICE) as UsbManager
            val connection = usbManager.openDevice(device) ?: return false

            val intf = findBulkInterface(device) ?: return false
            connection.claimInterface(intf, true)

            val endpoint = findBulkOutEndpoint(intf) ?: return false
            val data = buildTsplLabel(name, barcode)

            val sent = connection.bulkTransfer(endpoint, data, data.size, 5000)

            connection.releaseInterface(intf)
            connection.close()

            sent > 0
        } catch (e: Exception) {
            Log.e(TAG, "TSPL error: ${e.message}")
            false
        }
    }

    // =================================================
    // ESC/POS PRINT (RECEIPT TEXT)
    // =================================================
    private fun printEscPos(
        device: UsbDevice,
        text: String
    ): Boolean {
        return try {
            val usbManager = getSystemService(USB_SERVICE) as UsbManager
            val connection = usbManager.openDevice(device) ?: return false

            val intf = findBulkInterface(device) ?: return false
            connection.claimInterface(intf, true)

            val endpoint = findBulkOutEndpoint(intf) ?: return false
            val data = (text + "\n\n\n").toByteArray(Charsets.UTF_8)

            connection.bulkTransfer(endpoint, data, data.size, 5000)

            connection.releaseInterface(intf)
            connection.close()

            true
        } catch (e: Exception) {
            Log.e(TAG, "ESC/POS error: ${e.message}")
            false
        }
    }

    // =================================================
    // USB HELPERS
    // =================================================
    private fun findBulkInterface(device: UsbDevice): UsbInterface? {
        for (i in 0 until device.interfaceCount) {
            val intf = device.getInterface(i)
            for (j in 0 until intf.endpointCount) {
                if (intf.getEndpoint(j).type == UsbConstants.USB_ENDPOINT_XFER_BULK) {
                    return intf
                }
            }
        }
        return null
    }

    private fun findBulkOutEndpoint(intf: UsbInterface): UsbEndpoint? {
        for (i in 0 until intf.endpointCount) {
            val ep = intf.getEndpoint(i)
            if (
                ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK &&
                ep.direction == UsbConstants.USB_DIR_OUT
            ) {
                return ep
            }
        }
        return null
    }

    // =================================================
    // TSPL LABEL BUILDER (AMAN - TIDAK PENGARUH STRUK)
    // =================================================
    private fun buildTsplLabel(
        name: String,
        barcode: String
    ): ByteArray {

        val productName = name.take(16)

        fun slot(x: Int, y: Int): String = buildString {
            val barcodeWidth = 240
            val textX = x + (barcodeWidth / 2) - 20

            append(
                "BARCODE $x,$y,\"128\",75,1,0,2,2,\"$barcode\"\r\n"
            )
            append(
                "TEXT $textX,${y + 120},\"2\",0,1,1,\"$productName\"\r\n"
            )
        }

        val cmd =
            "SIZE 800,1200\r\n" +
            "GAP 0,0\r\n" +
            "DENSITY 7\r\n" +
            "SPEED 4\r\n" +
            "DIRECTION 1\r\n" +
            "CLS\r\n" +

            slot(60, 40) +
            slot(430, 40) +
            slot(60, 320) +
            slot(430, 320) +
            slot(60, 600) +
            slot(430, 600) +
            slot(60, 880) +
            slot(430, 880) +

            "PRINT 1,1\r\n"

        return cmd.toByteArray(Charsets.US_ASCII)
    }
}
