package com.worldvoice.worldvoice

import android.Manifest
import android.content.pm.PackageManager
import android.speech.tts.TextToSpeech
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val livePermissionChannel = "worldvoice/live_permissions"
    private val liveTtsChannel = "worldvoice/live_tts"
    private val cameraRequestCode = 7401
    private var pendingCameraResult: MethodChannel.Result? = null
    private var textToSpeech: TextToSpeech? = null
    private var ttsReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        textToSpeech = TextToSpeech(this) { status ->
            ttsReady = status == TextToSpeech.SUCCESS
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            livePermissionChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestCamera" -> requestCameraPermission(result)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            liveTtsChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text")?.trim().orEmpty()
                    val languageCode =
                        call.argument<String>("languageCode")?.trim().orEmpty()
                    speakTeacherText(text, languageCode, result)
                }
                "stop" -> {
                    textToSpeech?.stop()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun speakTeacherText(
        text: String,
        languageCode: String,
        result: MethodChannel.Result,
    ) {
        if (text.isEmpty()) {
            result.success(null)
            return
        }
        val engine = textToSpeech
        if (engine == null || !ttsReady) {
            result.error(
                "TTS_NOT_READY",
                "Text-to-speech is not ready yet.",
                null,
            )
            return
        }

        val locale = if (languageCode.isBlank()) {
            Locale.getDefault()
        } else {
            Locale.forLanguageTag(languageCode)
        }
        engine.language = locale
        engine.speak(
            text,
            TextToSpeech.QUEUE_FLUSH,
            null,
            "worldvoice_teacher_ai",
        )
        result.success(null)
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

    override fun onDestroy() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        ttsReady = false
        super.onDestroy()
    }
}
