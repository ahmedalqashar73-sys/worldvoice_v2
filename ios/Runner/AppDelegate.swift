import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let speechSynthesizer = AVSpeechSynthesizer()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let permissionChannel = FlutterMethodChannel(
      name: "worldvoice/live_permissions",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    permissionChannel.setMethodCallHandler { call, result in
      guard call.method == "requestCamera" else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized:
        result(true)
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
          DispatchQueue.main.async {
            result(granted)
          }
        }
      case .denied, .restricted:
        result(false)
      @unknown default:
        result(false)
      }
    }

    let ttsChannel = FlutterMethodChannel(
      name: "worldvoice/live_tts",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    ttsChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }

      switch call.method {
      case "speak":
        guard
          let args = call.arguments as? [String: Any],
          let text = (args["text"] as? String)?.trimmingCharacters(
            in: .whitespacesAndNewlines
          ),
          !text.isEmpty
        else {
          result(nil)
          return
        }

        let languageCode = (args["languageCode"] as? String)?
          .trimmingCharacters(in: .whitespacesAndNewlines)

        self.speechSynthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        if let code = languageCode, !code.isEmpty,
           let voice = AVSpeechSynthesisVoice(language: code) {
          utterance.voice = voice
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        self.speechSynthesizer.speak(utterance)
        result(nil)

      case "stop":
        self.speechSynthesizer.stopSpeaking(at: .immediate)
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
