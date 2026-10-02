package com.worldvoice.worldvoice

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val livePermissionChannel = "worldvoice/live_permissions"
    private val cameraRequestCode = 7401
    private var pendingCameraResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            livePermissionChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestCamera" -> requestCameraPermission(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun requestCameraPermission(result: MethodChannel.Result) {
        if (
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.CAMERA,
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }

        if (pendingCameraResult != null) {
            result.error(
                "CAMERA_REQUEST_ACTIVE",
                "A camera permission request is already active.",
                null,
            )
            return
        }

        pendingCameraResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CAMERA),
            cameraRequestCode,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != cameraRequestCode) return

        val granted =
            grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingCameraResult?.success(granted)
        pendingCameraResult = null
    }
}
