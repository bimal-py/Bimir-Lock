import AuthenticationServices
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  /// PERMANENT, exactly like the Android applicationId. It becomes part of the vault's absolute
  /// path on disk; renaming it later strands every iOS vault. Written here and in
  /// Runner.entitlements, and never parameterised.
  private static let appGroupId = "group.com.cklamib.bimirLock"

  private static let cryptoChannelName = "com.cklamib.bimirLock/vault_crypto"
  private static let nativeChannelName = "com.cklamib.bimirLock/native"

  /// Serial background queue: keychain and AES work must not run on the platform thread.
  private let vaultQueue = DispatchQueue(label: "com.cklamib.bimirLock.vault_crypto")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BimirNative") else {
      return
    }
    registerVaultCryptoChannel(messenger: registrar.messenger())
    registerNativeChannel(messenger: registrar.messenger())
  }

  // MARK: - com.cklamib.bimirLock/vault_crypto
  //
  // The SAME contract Kotlin implements. Without it every Dart database operation on iOS throws
  // MissingPluginException. Nothing here ever puts a value into a message, a log or an error.

  private func registerVaultCryptoChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: AppDelegate.cryptoChannelName, binaryMessenger: messenger)

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "vault_crypto_failed", message: "AppDelegate deallocated", details: nil))
        return
      }

      self.vaultQueue.async {
        let reply: Any?
        do {
          switch call.method {

          case "ensureKey":
            let args = call.arguments as? [String: Any]
            // A missing or null "kcv" both mean "first run".
            let storedKcv = args?["kcv"] as? String
            reply = [
              "kcv": try VaultCrypto.ensureKey(storedKcv: storedKcv),
              "securityLevel": "keychain",
            ]

          case "encryptBatch":
            guard let values = AppDelegate.stringList(from: call) else {
              AppDelegate.reply(result, FlutterError(
                code: "vault_crypto_failed",
                message: "encryptBatch expects {\"values\": [String]}", details: nil))
              return
            }
            reply = try values.map { try VaultCrypto.encrypt($0) }

          case "decryptBatch":
            guard let values = AppDelegate.stringList(from: call) else {
              AppDelegate.reply(result, FlutterError(
                code: "vault_crypto_failed",
                message: "decryptBatch expects {\"values\": [String]}", details: nil))
              return
            }
            // Same length, same order — the caller indexes into it positionally.
            reply = try values.map { stored -> [String: Any] in
              let decoded = try VaultCrypto.decode(stored)
              switch decoded.kind {
              case .ok:
                return ["status": "ok", "value": decoded.value ?? ""]
              case .plain:
                return ["status": "plain", "value": decoded.value ?? ""]
              }
            }

          default:
            AppDelegate.reply(result, FlutterMethodNotImplemented)
            return
          }
        } catch let failure as VaultCrypto.Failure {
          AppDelegate.reply(result, AppDelegate.flutterError(for: failure))
          return
        } catch {
          // CLASS NAME ONLY. Never the error's description — it could quote input.
          AppDelegate.reply(result, FlutterError(
            code: "vault_crypto_failed",
            message: String(describing: type(of: error)), details: nil))
          return
        }

        AppDelegate.reply(result, reply)
      }
    }
  }

  private static func stringList(from call: FlutterMethodCall) -> [String]? {
    guard let args = call.arguments as? [String: Any] else { return nil }
    return args["values"] as? [String]
  }

  /// Every FlutterResult is delivered on the main thread.
  private static func reply(_ result: @escaping FlutterResult, _ value: Any?) {
    DispatchQueue.main.async { result(value) }
  }

  private static func flutterError(for failure: VaultCrypto.Failure) -> FlutterError {
    switch failure {
    case .keyUnavailable(let code):
      return FlutterError(code: code, message: "vault key: \(code)", details: nil)
    case .keychain(let status):
      return FlutterError(code: "keystore_unavailable",
                          message: "keychain OSStatus \(status)", details: nil)
    case .invalidEnvelope(let reason):
      return FlutterError(code: "vault_crypto_failed",
                          message: "envelope: \(reason)", details: nil)
    }
  }

  // MARK: - com.cklamib.bimirLock/native

  private func registerNativeChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: AppDelegate.nativeChannelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "databaseDirectory":
        result(AppDelegate.databaseDirectory())
      case "autofillEnabled":
        AppDelegate.autofillEnabled(result)
      case "openAutofillSettings":
        AppDelegate.openAutofillSettings(result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Whether Bimir Lock is switched on under Settings › General › AutoFill & Passwords.
  private static func autofillEnabled(_ result: @escaping FlutterResult) {
    ASCredentialIdentityStore.shared.getState { state in
      DispatchQueue.main.async { result(state.isEnabled) }
    }
  }

  /// The shortest way to switching AutoFill on that this iOS has: Apple's own "turn on"
  /// prompt (18+), the AutoFill & Passwords page for this app (17), or the Settings app.
  /// Answers whether it is now on (18+) or whether the page opened.
  private static func openAutofillSettings(_ result: @escaping FlutterResult) {
    if #available(iOS 18.0, *) {
      ASSettingsHelper.requestToTurnOnCredentialProviderExtension { turnedOn in
        DispatchQueue.main.async { result(turnedOn) }
      }
    } else if #available(iOS 17.0, *) {
      ASSettingsHelper.openCredentialProviderAppSettings { error in
        DispatchQueue.main.async { result(error == nil) }
      }
    } else if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
    } else {
      result(false)
    }
  }

  /// The App Group directory the sqflite database lives in.
  ///
  /// NEVER returns a substitute path. A Documents fallback would silently open a SECOND, empty
  /// vault; the user would fill it, signing would later be fixed, the app would switch to the
  /// container, and the Documents vault would become unreachable — indistinguishable from
  /// deletion (checklist 2). Failing loudly is correct: there is no existing iOS data to
  /// endanger, and the failure is fully repaired by registering the App Group in the portal.
  private static func databaseDirectory() -> Any {
    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupId)
    else {
      return FlutterError(
        code: "app_group_unavailable",
        message: "App Group \(appGroupId) is not available to this build. Check "
          + "Runner.entitlements, that the group is registered for this App ID in the Apple "
          + "Developer portal, and that the provisioning profile in use carries it.",
        details: nil)
    }

    var dir = container.appendingPathComponent("Database", isDirectory: true)
    do {
      // .completeUntilFirstUserAuthentication deliberately matches the key's
      // kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly. .complete would make the database
      // unopenable when the system launches an AutoFill extension on a locked device.
      try FileManager.default.createDirectory(
        at: dir,
        withIntermediateDirectories: true,
        attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])

      // The App Group container IS included in iCloud backup; a ThisDeviceOnly keychain item is
      // NOT. Without this flag, a restore onto new hardware yields a database full of rows that
      // can never be decrypted — worse than plaintext, because it looks like the data survived
      // (checklist 22). Excluding it makes the database and the key share one fate.
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try dir.setResourceValues(values)

      return dir.path
    } catch {
      // CLASS NAME ONLY, and no path in the details.
      return FlutterError(code: "container_dir_failed",
                          message: String(describing: type(of: error)), details: nil)
    }
  }
}
