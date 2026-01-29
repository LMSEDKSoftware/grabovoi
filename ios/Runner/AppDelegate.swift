import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Configurar método channel para solicitar permisos de fotos
    let controller = window?.rootViewController as! FlutterViewController
    let photoPermissionChannel = FlutterMethodChannel(
      name: "com.manigrab/photos_permission",
      binaryMessenger: controller.binaryMessenger
    )
    
    photoPermissionChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "requestPhotoPermission" {
        self.requestPhotoPermission(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func requestPhotoPermission(result: @escaping FlutterResult) {
    // Usar APIs compatibles con iOS 12.0+
    let status: PHAuthorizationStatus
    
    if #available(iOS 14, *) {
      // iOS 14+: usar authorizationStatus(for:)
      status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    } else {
      // iOS 12-13: usar authorizationStatus() sin parámetros
      status = PHPhotoLibrary.authorizationStatus()
    }
    
    switch status {
    case .authorized:
      // Ya tiene permiso
      result(true)
    case .denied, .restricted:
      // Denegado o restringido
      result(false)
    case .notDetermined:
      // No se ha solicitado aún, solicitar ahora
      if #available(iOS 14, *) {
        // iOS 14+: usar requestAuthorization(for:handler:)
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
          DispatchQueue.main.async {
            result(newStatus == .authorized || newStatus == .limited)
          }
        }
      } else {
        // iOS 12-13: usar requestAuthorization(_:)
        PHPhotoLibrary.requestAuthorization { newStatus in
          DispatchQueue.main.async {
            result(newStatus == .authorized)
          }
        }
      }
    @unknown default:
      result(false)
    }
  }
}
