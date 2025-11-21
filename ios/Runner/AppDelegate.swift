import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 2. Get the API Key from the environment variables
//    let googleMapsApiKey = (Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String)!
    // 3. Provide the API Key to GMSServices
    GMSServices.provideAPIKey("your google maps api key")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
