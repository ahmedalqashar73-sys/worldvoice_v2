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
    private var ttsInitializationFailed = false
    private var pendingSpeech: Triple<String, String, MethodChannel.Result>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        textToSpeech = TextToSpeech(this) { status ->
            runOnUiThread {
                ttsReady = status == TextToSpeech.SUCCESS
                ttsInitializationFailed = !ttsReady
                val queued = pendingSpeech
                pendingSpeech = null
                if (queued != null) {
                    if (ttsReady) {
                        speakTeacherText(queued.first, queued.second, queued.third)
                    } else {
                        queued.third.error(
                            "TTS_NOT_READY",
                            "Text-to-speech initialization failed.",
                            null,
                        )
                    }
                }
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
                    pendingSpeech?.third?.error(
                        "TTS_CANCELED", "Speech was stopped.", null,
                    )
                    pendingSpeech = null
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
        if (engine == null || ttsInitializationFailed) {
            result.error("TTS_NOT_READY", "Text-to-speech is unavailable.", null)
            return
        }
        if (!ttsReady) {
            // Flutter may request the first answer while Android TTS is
            // still initializing. Queue the latest reply instead of dropping it.
            pendingSpeech?.third?.error(
                "TTS_SUPERSEDED", "A newer Teacher AI reply arrived.", null,
            )
            pendingSpeech = Triple(text, languageCode, result)
            return
        }

        val locale = if (languageCode.isBlank()) {
            Locale.getDefault()
        } else {
            Locale.forLanguageTag(languageCode)
        }
        val languageStatus = engine.setLanguage(locale)
        if (
            languageStatus == TextToSpeech.LANG_MISSING_DATA ||
            languageStatus == TextToSpeech.LANG_NOT_SUPPORTED
        ) {
            result.error(
                "TTS_LANGUAGE_UNAVAILABLE",
                "This device does not have a voice for the selected language.",
                null,
            )
            return
        }
        val status = engine.speak(
            text,
            TextToSpeech.QUEUE_FLUSH,
            null,
            "worldvoice_teacher_ai",
        )
        if (status == TextToSpeech.ERROR) {
            result.error("TTS_PLAY_FAILED", "Could not play speech.", null)
        } else {
            result.success(null)
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

    override fun onDestroy() {
        pendingSpeech?.third?.error(
            "TTS_CANCELED", "The speech session has ended.", null,
        )
        pendingSpeech = null
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        ttsReady = false
        super.onDestroy()
    }
}
