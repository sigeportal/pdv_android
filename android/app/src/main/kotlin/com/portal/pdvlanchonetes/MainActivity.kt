package com.portal.pdvlanchonetes

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.portal.pdvlanchonetes/usb_printer"
    private val usbPermissionAction = "com.portal.pdvlanchonetes.USB_PERMISSION"
    private lateinit var usbManager: UsbManager
    private var pendingResult: MethodChannel.Result? = null
    private var pendingData: ByteArray? = null

    private val permissionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action != usbPermissionAction) return

            val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
            }

            val result = pendingResult
            val data = pendingData
            pendingResult = null
            pendingData = null

            if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false) &&
                device != null && data != null
            ) {
                writeToUsb(device, data, result)
            } else {
                result?.error("USB_PERMISSION_DENIED", "Permissao USB negada.", null)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        usbManager = getSystemService(Context.USB_SERVICE) as UsbManager

        val filter = IntentFilter(usbPermissionAction)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(permissionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(permissionReceiver, filter)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getUsbDevices" -> result.success(getUsbDevices())
                    "writeUsb" -> handleWrite(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun getUsbDevices(): List<Map<String, Any>> {
        return usbManager.deviceList.values.map { device ->
            val label = try {
                listOfNotNull(device.manufacturerName, device.productName)
                    .joinToString(" ")
                    .ifBlank { device.deviceName }
            } catch (_: SecurityException) {
                device.deviceName
            }

            mapOf(
                "vendorId" to device.vendorId,
                "productId" to device.productId,
                "name" to label
            )
        }
    }

    private fun handleWrite(call: MethodCall, result: MethodChannel.Result) {
        val vendorId = call.argument<Int>("vendorId")
        val productId = call.argument<Int>("productId")
        val data = call.argument<ByteArray>("data")

        if (vendorId == null || productId == null || data == null) {
            result.error("INVALID_ARGUMENTS", "Impressora USB ou dados invalidos.", null)
            return
        }

        val device = usbManager.deviceList.values.firstOrNull {
            it.vendorId == vendorId && it.productId == productId
        }
        if (device == null) {
            result.error("USB_NOT_FOUND", "Impressora USB nao encontrada.", null)
            return
        }

        if (usbManager.hasPermission(device)) {
            writeToUsb(device, data, result)
            return
        }

        if (pendingResult != null) {
            result.error("USB_BUSY", "Ja existe uma solicitacao USB em andamento.", null)
            return
        }

        pendingResult = result
        pendingData = data
        val permissionIntent =
            PendingIntent.getBroadcast(
                this,
                0,
                Intent(usbPermissionAction).setPackage(packageName),
                PendingIntent.FLAG_IMMUTABLE
            )
        usbManager.requestPermission(device, permissionIntent)
    }

    private fun writeToUsb(
        device: UsbDevice,
        data: ByteArray,
        result: MethodChannel.Result?
    ) {
        Thread {
            var connection: android.hardware.usb.UsbDeviceConnection? = null
            try {
                val interfaceAndEndpoint = device.interfaceList()
                    .flatMap { usbInterface ->
                        (0 until usbInterface.endpointCount).map { index ->
                            Pair(usbInterface, usbInterface.getEndpoint(index))
                        }
                    }
                    .firstOrNull { (_, endpoint) ->
                        endpoint.type == UsbConstants.USB_ENDPOINT_XFER_BULK &&
                            endpoint.direction == UsbConstants.USB_DIR_OUT
                    }
                    ?: throw IllegalStateException("Saida USB da impressora nao encontrada.")

                val usbInterface = interfaceAndEndpoint.first
                val endpoint = interfaceAndEndpoint.second
                val openedConnection = usbManager.openDevice(device)
                    ?: throw IllegalStateException("Nao foi possivel abrir a impressora USB.")
                connection = openedConnection

                if (!openedConnection.claimInterface(usbInterface, true)) {
                    throw IllegalStateException("Nao foi possivel acessar a impressora USB.")
                }

                var offset = 0
                while (offset < data.size) {
                    val chunkSize = minOf(16 * 1024, data.size - offset)
                    val chunk = data.copyOfRange(offset, offset + chunkSize)
                    val written =
                        openedConnection.bulkTransfer(endpoint, chunk, chunk.size, 5000)
                    if (written <= 0) {
                        throw IllegalStateException("Falha ao enviar dados para a impressora USB.")
                    }
                    offset += written
                }

                runOnUiThread { result?.success(true) }
            } catch (error: Exception) {
                runOnUiThread {
                    result?.error("USB_WRITE_ERROR", error.message ?: error.toString(), null)
                }
            } finally {
                connection?.close()
            }
        }.start()
    }

    private fun UsbDevice.interfaceList() =
        (0 until interfaceCount).map { getInterface(it) }

    override fun onDestroy() {
        try {
            unregisterReceiver(permissionReceiver)
        } catch (_: IllegalArgumentException) {
            // Receiver was not registered.
        }
        super.onDestroy()
    }
}
