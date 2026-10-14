package br.org.ipb.ipb_conferencia

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream
import java.nio.charset.Charset
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val printerChannelName = "br.org.ipb.conferencia/thermal_printer"
    private val bluetoothPermissionRequest = 5808
    private var pendingBluetoothResult: MethodChannel.Result? = null
    private var pendingBluetoothAction: (() -> Unit)? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, printerChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listPairedDevices" -> withBluetoothPermission(result) {
                        listPairedDevices(result)
                    }
                    "printText" -> withBluetoothPermission(result) {
                        val address = call.argument<String>("address")
                        val text = call.argument<String>("text") ?: ""
                        val cutPaper = call.argument<Boolean>("cutPaper") ?: false
                        if (address.isNullOrBlank()) {
                            result.error("PRINTER_REQUIRED", "Impressora Bluetooth não selecionada.", null)
                            return@withBluetoothPermission
                        }
                        printText(address, text, cutPaper, result)
                    }
                    "printRawBytes" -> withBluetoothPermission(result) {
                        val address = call.argument<String>("address")
                        val bytes = call.argument<ByteArray>("bytes") ?: byteArrayOf()
                        val cutPaper = call.argument<Boolean>("cutPaper") ?: false
                        if (address.isNullOrBlank()) {
                            result.error("PRINTER_REQUIRED", "Impressora Bluetooth não selecionada.", null)
                            return@withBluetoothPermission
                        }
                        printRawBytes(address, bytes, cutPaper, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasBluetoothPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.BLUETOOTH_CONNECT
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun withBluetoothPermission(result: MethodChannel.Result, action: () -> Unit) {
        if (hasBluetoothPermission()) {
            action()
            return
        }
        if (pendingBluetoothResult != null) {
            result.error("PERMISSION_IN_PROGRESS", "Aguarde a autorização Bluetooth em andamento.", null)
            return
        }
        pendingBluetoothResult = result
        pendingBluetoothAction = action
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.BLUETOOTH_CONNECT),
                bluetoothPermissionRequest
            )
        } else {
            action()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != bluetoothPermissionRequest) return

        val result = pendingBluetoothResult
        val action = pendingBluetoothAction
        pendingBluetoothResult = null
        pendingBluetoothAction = null

        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            action?.invoke()
        } else {
            result?.error(
                "BLUETOOTH_PERMISSION_DENIED",
                "Permita o acesso a Dispositivos Próximos / Bluetooth para usar a impressora.",
                null
            )
        }
    }

    private fun bluetoothAdapter(): BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

    private fun listPairedDevices(result: MethodChannel.Result) {
        try {
            val adapter = bluetoothAdapter()
            if (adapter == null) {
                result.error("BLUETOOTH_UNAVAILABLE", "Este aparelho não possui Bluetooth.", null)
                return
            }
            if (!adapter.isEnabled) {
                result.error("BLUETOOTH_DISABLED", "Ative o Bluetooth do aparelho.", null)
                return
            }
            val devices = adapter.bondedDevices
                .sortedWith(compareBy<BluetoothDevice> { it.name ?: "" }.thenBy { it.address })
                .map {
                    mapOf(
                        "name" to (it.name ?: "Dispositivo Bluetooth"),
                        "address" to it.address
                    )
                }
            result.success(devices)
        } catch (e: SecurityException) {
            result.error("BLUETOOTH_PERMISSION_DENIED", "Permissão Bluetooth negada: ${e.message}", null)
        } catch (e: Exception) {
            result.error("BLUETOOTH_LIST_FAILED", e.message, null)
        }
    }

    @Throws(Exception::class)
    private fun connectSocket(device: BluetoothDevice): BluetoothSocket {
        val sppUuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
        var socket: BluetoothSocket? = null

        // Tentativa 1: Socket RFCOMM padrão SPP
        try {
            socket = device.createRfcommSocketToServiceRecord(sppUuid)
            socket.connect()
            return socket
        } catch (e1: Exception) {
            try { socket?.close() } catch (ignored: Exception) {}
        }

        // Tentativa 2: Fallback canal 1 via reflexão (Resolve POS-58 e chipsets MediaTek/Qualcomm)
        try {
            val method = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
            socket = method.invoke(device, 1) as BluetoothSocket
            socket.connect()
            return socket
        } catch (e2: Exception) {
            try { socket?.close() } catch (ignored: Exception) {}
        }

        // Tentativa 3: Socket Insecure SPP
        socket = device.createInsecureRfcommSocketToServiceRecord(sppUuid)
        socket.connect()
        return socket
    }

    private fun printText(
        address: String,
        text: String,
        cutPaper: Boolean,
        result: MethodChannel.Result
    ) {
        Thread {
            var socket: BluetoothSocket? = null
            var output: OutputStream? = null
            try {
                val adapter = bluetoothAdapter()
                if (adapter == null) {
                    runOnUiThread {
                        result.error("BLUETOOTH_UNAVAILABLE", "Este aparelho não possui Bluetooth.", null)
                    }
                    return@Thread
                }
                if (!adapter.isEnabled) {
                    runOnUiThread {
                        result.error("BLUETOOTH_DISABLED", "Ative o Bluetooth do aparelho.", null)
                    }
                    return@Thread
                }

                try {
                    if (adapter.isDiscovering) {
                        adapter.cancelDiscovery()
                    }
                } catch (ignored: Exception) {}

                val device = adapter.getRemoteDevice(address)
                socket = connectSocket(device)
                output = socket.outputStream

                val charset = try {
                    Charset.forName("CP850")
                } catch (e: Exception) {
                    try {
                        Charset.forName("ISO-8859-1")
                    } catch (e2: Exception) {
                        Charset.defaultCharset()
                    }
                }

                output.write(byteArrayOf(0x1B, 0x40)) // ESC @ (Reset)
                output.write(byteArrayOf(0x1B, 0x74, 0x02)) // Seleciona code page CP850
                output.write(text.toByteArray(charset))
                output.write(byteArrayOf(0x0A, 0x0A, 0x0A, 0x0A)) // 4 quebras de linha para sair da guilhotina/serrilha
                if (cutPaper) {
                    output.write(byteArrayOf(0x1D, 0x56, 0x42, 0x00)) // GS V 66 0 (Corte)
                }
                output.flush()

                // Pausa crucial de 1000ms com o socket ABERTO para drenar o buffer de RFCOMM para a impressora
                try {
                    Thread.sleep(1000)
                } catch (ignored: InterruptedException) {}

                runOnUiThread { result.success(true) }
            } catch (e: SecurityException) {
                runOnUiThread {
                    result.error("BLUETOOTH_PERMISSION_DENIED", "Permissão Bluetooth negada: ${e.message}", null)
                }
            } catch (e: Exception) {
                runOnUiThread {
                    result.error("PRINT_FAILED", "Falha ao imprimir: ${e.message}", null)
                }
            } finally {
                try { output?.close() } catch (ignored: Exception) {}
                try { socket?.close() } catch (ignored: Exception) {}
            }
        }.start()
    }

    private fun printRawBytes(
        address: String,
        bytes: ByteArray,
        cutPaper: Boolean,
        result: MethodChannel.Result
    ) {
        Thread {
            var socket: BluetoothSocket? = null
            var output: OutputStream? = null
            try {
                val adapter = bluetoothAdapter()
                if (adapter == null) {
                    runOnUiThread {
                        result.error("BLUETOOTH_UNAVAILABLE", "Este aparelho não possui Bluetooth.", null)
                    }
                    return@Thread
                }
                if (!adapter.isEnabled) {
                    runOnUiThread {
                        result.error("BLUETOOTH_DISABLED", "Ative o Bluetooth do aparelho.", null)
                    }
                    return@Thread
                }

                try {
                    if (adapter.isDiscovering) {
                        adapter.cancelDiscovery()
                    }
                } catch (ignored: Exception) {}

                val device = adapter.getRemoteDevice(address)
                socket = connectSocket(device)
                output = socket.outputStream

                output.write(byteArrayOf(0x1B, 0x40)) // ESC @ (Reset)
                output.write(bytes)
                output.write(byteArrayOf(0x0A, 0x0A, 0x0A, 0x0A)) // 4 quebras de linha
                if (cutPaper) {
                    output.write(byteArrayOf(0x1D, 0x56, 0x42, 0x00))
                }
                output.flush()

                // Pausa crucial de 1000ms com o socket ABERTO
                try {
                    Thread.sleep(1000)
                } catch (ignored: InterruptedException) {}

                runOnUiThread { result.success(true) }
            } catch (e: SecurityException) {
                runOnUiThread {
                    result.error("BLUETOOTH_PERMISSION_DENIED", "Permissão Bluetooth negada: ${e.message}", null)
                }
            } catch (e: Exception) {
                runOnUiThread {
                    result.error("PRINT_FAILED", "Falha ao imprimir: ${e.message}", null)
                }
            } finally {
                try { output?.close() } catch (ignored: Exception) {}
                try { socket?.close() } catch (ignored: Exception) {}
            }
        }.start()
    }
}
