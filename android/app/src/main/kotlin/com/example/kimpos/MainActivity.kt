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
                    // PRINT BARCODE (TSPL)
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
                            printTsplLabel(device, name, barcode)
                        }.start()

                        result.success(true)
                    }

                    // =================================================
                    // PRINT RECEIPT (ESC/POS)
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
                            printEscPos(device, text)
                        }.start()

                        result.success(true)
                    }

                    // =================================================
                    // OPEN CASH DRAWER (ESC/POS)
                    // =================================================
                    "openCashDrawer" -> {
                        val deviceName = call.argument<String>("deviceName") ?: ""

                        val device = usbManager.deviceList.values.firstOrNull {
                            deviceName.startsWith(it.deviceName)
                        }

                        if (device == null || !usbManager.hasPermission(device)) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        Thread {
                            openCashDrawer(device)
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
    // TSPL PRINT
    // =================================================
    private fun printTsplLabel(device: UsbDevice, name: String, barcode: String): Boolean {
        return try {
            val usbManager = getSystemService(USB_SERVICE) as UsbManager
            val connection = usbManager.openDevice(device) ?: return false

            val intf = findBulkInterface(device) ?: return false
            connection.claimInterface(intf, true)

            val endpoint = findBulkOutEndpoint(intf) ?: return false
            val data = buildTsplLabel(name, barcode)

            connection.bulkTransfer(endpoint, data, data.size, 5000)

            connection.releaseInterface(intf)
            connection.close()
            true
        } catch (e: Exception) {
            Log.e(TAG, "TSPL error: ${e.message}")
            false
        }
    }

    // =================================================
    // ESC/POS PRINT
    // =================================================
    private fun printEscPos(device: UsbDevice, text: String): Boolean {
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
    // OPEN CASH DRAWER
    // =================================================
    private fun openCashDrawer(device: UsbDevice): Boolean {
        return try {
            val usbManager = getSystemService(USB_SERVICE) as UsbManager
            val connection = usbManager.openDevice(device) ?: return false

            val intf = findBulkInterface(device) ?: return false
            connection.claimInterface(intf, true)

            val endpoint = findBulkOutEndpoint(intf) ?: return false

            val cmd = byteArrayOf(
                0x1B, 0x70, 0x00, 0x19.toByte(), 0xFA.toByte()
            )

            connection.bulkTransfer(endpoint, cmd, cmd.size, 3000)

            connection.releaseInterface(intf)
            connection.close()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Drawer error: ${e.message}")
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
            if (ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK &&
                ep.direction == UsbConstants.USB_DIR_OUT
            ) {
                return ep
            }
        }
        return null
    }

    private fun buildTsplLabel(name: String, barcode: String): ByteArray {
        val productName = name.take(16)

        fun slot(x: Int, y: Int): String = buildString {
            append("BARCODE $x,$y,\"128\",75,1,0,2,2,\"$barcode\"\r\n")
            append("TEXT ${x + 80},${y + 120},\"2\",0,1,1,\"$productName\"\r\n")
        }

        val cmd =
            "SIZE 800,1200\r\n" +
            "CLS\r\n" +
            slot(60, 40) +
            "PRINT 1,1\r\n"

        return cmd.toByteArray(Charsets.US_ASCII)
    }
}
