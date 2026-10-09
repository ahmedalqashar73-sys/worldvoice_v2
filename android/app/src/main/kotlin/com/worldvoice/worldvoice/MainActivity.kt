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
    // Retain only the latest AI sentence while Android initializes TTS.
    private var pendingTeacherSpeech: Pair<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        textToSpeech = TextToSpeech(this) { status ->
            ttsReady = status == TextToSpeech.SUCCESS
            if (ttsReady) {
                runOnUiThread {
                    val pending = pendingTeacherSpeech
                    pendingTeacherSpeech = null
                    if (pending != null) {
                        speakReadyTeacherText(pending.first, pending.second)
                    }
                }
            } else {
                pendingTeacherSpeech = null
            }
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
                    pendingTeacherSpeech = null
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
        if (!ttsReady || textToSpeech == null) {
            // The first reply can arrive while the Android engine starts.
            // Queue it rather than dropping the AI voice silently.
            pendingTeacherSpeech = Pair(text, languageCode)
            result.success(null)
            return
        }
        val output = speakReadyTeacherText(text, languageCode)
        if (output == TextToSpeech.SUCCESS) {
            result.success(null)
        } else {
            result.error("TTS_FAILED", "The device could not speak the AI reply.", null)
        }
    }

    private fun speakReadyTeacherText(text: String, languageCode: String): Int {
        val engine = textToSpeech ?: return TextToSpeech.ERROR
        val targetLocale = if (languageCode.isBlank()) {
            Locale.getDefault()
        } else {
            Locale.forLanguageTag(languageCode.replace('_', '-'))
        }
        val languageResult = engine.setLanguage(targetLocale)
        if (languageResult == TextToSpeech.LANG_MISSING_DATA ||
            languageResult == TextToSpeech.LANG_NOT_SUPPORTED
        ) {
            // Keep a working voice when the requested language pack is missing.
            engine.setLanguage(Locale.getDefault())
        }
        return engine.speak(
            text,
            TextToSpeech.QUEUE_FLUSH,
            null,
            "worldvoice_teacher_ai",
        )
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
        pendingTeacherSpeech = null
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        ttsReady = false
        super.onDestroy()
    }
}
