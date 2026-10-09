package com.worldvoice.worldvoice

import android.Manifest
import android.content.pm.PackageManager
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.media.AudioAttributes
import android.os.Handler
import android.os.Looper
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
    private var ttsFailed = false
    private val speechHandler = Handler(Looper.getMainLooper())
    private var speechResult: MethodChannel.Result? = null
    private var speechId = 0
    private var awaitSpeechCompletion = false
    private val speechTimeout = Runnable {
        pendingTeacherSpeech = null
        textToSpeech?.stop()
        finishSpeech("TTS_TIMEOUT", "Speech did not start. Check the device speech engine and language pack.")
    }

    private fun finishSpeech(code: String? = null, message: String? = null) {
        speechHandler.removeCallbacks(speechTimeout)
        val result = speechResult
        speechResult = null
        if (code == null) result?.success(null) else result?.error(code, message, null)
    }
    // Retain only the latest AI sentence while Android initializes TTS.
    private var pendingTeacherSpeech: Pair<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        textToSpeech = TextToSpeech(this) { status ->
            runOnUiThread {
                ttsReady = status == TextToSpeech.SUCCESS
                ttsFailed = !ttsReady
                if (ttsReady) {
                    textToSpeech?.setAudioAttributes(AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
                    textToSpeech?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                        override fun onStart(utteranceId: String?) {
                            runOnUiThread {
                                if (utteranceId == "worldvoice_teacher_ai_$speechId") {
                                    if (awaitSpeechCompletion) {
                                        speechHandler.removeCallbacks(speechTimeout)
                                        speechHandler.postDelayed(speechTimeout, 120000)
                                    } else finishSpeech()
                                }
                            }
                        }
                        override fun onDone(utteranceId: String?) {
                            runOnUiThread {
                                if (utteranceId == "worldvoice_teacher_ai_$speechId") finishSpeech()
                            }
                        }
                        @Deprecated("Android legacy error callback")
                        override fun onError(utteranceId: String?) {
                            runOnUiThread {
                                if (utteranceId == "worldvoice_teacher_ai_$speechId") {
                                    finishSpeech("TTS_FAILED", "The device could not play the AI voice.")
                                }
                            }
                        }
                    })
                    val pending = pendingTeacherSpeech
                    pendingTeacherSpeech = null
                    if (pending != null && speakReadyTeacherText(pending.first, pending.second) != TextToSpeech.SUCCESS) {
                        finishSpeech("TTS_FAILED", "Install the speech voice for the room language in Android settings.")
                    }
                } else {
                    pendingTeacherSpeech = null
                    finishSpeech("TTS_UNAVAILABLE", "The Android speech engine could not initialize.")
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
                    awaitSpeechCompletion = call.argument<Boolean>("awaitCompletion") == true
                    speakTeacherText(text, languageCode, result)
                }
                "stop" -> {
                    pendingTeacherSpeech = null
                    finishSpeech("TTS_CANCELLED", "Speech was stopped.")
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
        if (ttsFailed) {
            result.error("TTS_UNAVAILABLE", "Enable a text-to-speech engine in Android settings and restart the app.", null)
            return
        }
        finishSpeech("TTS_CANCELLED", "A newer reply replaced this speech.")
        speechResult = result
        speechId++
        speechHandler.postDelayed(speechTimeout, 15000)
        if (!ttsReady || textToSpeech == null) {
            pendingTeacherSpeech = Pair(text, languageCode)
            return
        }
        if (speakReadyTeacherText(text, languageCode) != TextToSpeech.SUCCESS) {
            finishSpeech("TTS_FAILED", "Install the speech voice for the room language in Android settings.")
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
            return TextToSpeech.ERROR
        }
        return engine.speak(
            text,
            TextToSpeech.QUEUE_FLUSH,
            null,
            "worldvoice_teacher_ai_$speechId",
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
        finishSpeech("TTS_CANCELLED", "The activity closed.")
        pendingTeacherSpeech = null
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        ttsReady = false
        super.onDestroy()
    }
}
