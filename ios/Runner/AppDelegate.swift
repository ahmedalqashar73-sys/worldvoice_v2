import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "WorldVoiceLivePermissions"
    )
    let channel = FlutterMethodChannel(
      name: "worldvoice/live_permissions",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
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
  }
}
