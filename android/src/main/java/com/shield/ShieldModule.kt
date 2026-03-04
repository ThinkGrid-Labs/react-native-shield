package com.shield

import com.facebook.react.bridge.ReactApplicationContext
import java.io.File
import java.io.BufferedReader
import java.io.InputStreamReader
import java.security.MessageDigest
import android.provider.Settings
import android.content.pm.PackageManager
import android.content.pm.Signature
import com.facebook.react.bridge.LifecycleEventListener
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.UiThreadUtil

class ShieldModule(reactContext: ReactApplicationContext) :
  NativeShieldSpec(reactContext) {

  private var isClipboardProtectionEnabled = false
  private val lifecycleEventListener = object : LifecycleEventListener {
      override fun onHostResume() {}
      override fun onHostPause() {
          if (isClipboardProtectionEnabled) {
              val clipboard = reactApplicationContext.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
              clipboard.setPrimaryClip(ClipData.newPlainText("", ""))
          }
      }
      override fun onHostDestroy() {}
  }

  init {
      reactApplicationContext.addLifecycleEventListener(lifecycleEventListener)
  }

  override fun isRooted(): Boolean {
    return checkRootMethod1() || checkRootMethod2() || checkRootMethod3()
  }

  override fun isEmulator(): Boolean {
    return (android.os.Build.BRAND.startsWith("generic") && android.os.Build.DEVICE.startsWith("generic"))
      || android.os.Build.FINGERPRINT.startsWith("generic")
      || android.os.Build.FINGERPRINT.startsWith("unknown")
      || android.os.Build.HARDWARE.contains("goldfish")
      || android.os.Build.HARDWARE.contains("ranchu")
      || android.os.Build.MODEL.contains("google_sdk")
      || android.os.Build.MODEL.contains("Emulator")
      || android.os.Build.MODEL.contains("Android SDK built for x86")
      || android.os.Build.MANUFACTURER.contains("Genymotion")
      || android.os.Build.PRODUCT.contains("sdk_google")
      || android.os.Build.PRODUCT.contains("google_sdk")
      || android.os.Build.PRODUCT.contains("sdk")
      || android.os.Build.PRODUCT.contains("sdk_x86")
      || android.os.Build.PRODUCT.contains("sdk_gphone64_arm64")
      || android.os.Build.PRODUCT.contains("vbox86p")
      || android.os.Build.PRODUCT.contains("emulator")
      || android.os.Build.PRODUCT.contains("simulator")
  }

  override fun isDebuggerAttached(): Boolean {
    return android.os.Debug.isDebuggerConnected() || android.os.Debug.waitingForDebugger()
  }

  override fun verifySignature(expectedHash: String): Boolean {
    try {
        val packageInfo = reactApplicationContext.packageManager.getPackageInfo(
            reactApplicationContext.packageName,
            PackageManager.GET_SIGNATURES
        )
        val signatures = packageInfo.signatures
        if (signatures.isNullOrEmpty()) return false

        val md = MessageDigest.getInstance("SHA-256")
        for (signature in signatures) {
            md.update(signature.toByteArray())
            val hexString = md.digest().joinToString("") { "%02x".format(it) }
            // Compare case-insensitive
            if (hexString.equals(expectedHash, ignoreCase = true)) {
                return true
            }
        }
    } catch (e: Exception) {
        return false
    }
    return false
  }

  override fun isHooked(): Boolean {
    val suspiciousLibraries = arrayOf(
        "de.robv.android.xposed.XposedBridge",
        "com.saurik.substrate.MS\$SubstrateClass",
        "com.saurik.substrate.MS"
    )
    for (library in suspiciousLibraries) {
        try {
            Class.forName(library)
            return true
        } catch (e: ClassNotFoundException) {
            // Class not found, which is good
        }
    }
    // Also check for frida server running or files
    val paths = arrayOf("/data/local/tmp/frida-server", "/system/bin/app_process", "/system/bin/app_process32", "/system/bin/app_process64")
    for (path in paths) {
        if (path.contains("frida-server") && File(path).exists()) {
             return true
        }
    }
    return false
  }

  override fun isDeveloperModeEnabled(): Boolean {
    val devOptions = Settings.Secure.getInt(
        reactApplicationContext.contentResolver,
        Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
        0
    ) != 0

    val adbEnabled = Settings.Secure.getInt(
        reactApplicationContext.contentResolver,
        Settings.Global.ADB_ENABLED,
        0
    ) != 0

    return devOptions || adbEnabled
  }

  override fun isVPNDetected(): Boolean {
      val connectivityManager = reactApplicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
      val activeNetwork = connectivityManager.activeNetwork ?: return false
      val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork) ?: return false
      return capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
  }

  override fun protectClipboard(protect: Boolean, promise: com.facebook.react.bridge.Promise) {
      isClipboardProtectionEnabled = protect
      promise.resolve(null)
  }

  override fun authenticateWithBiometrics(promptMessage: String, promise: com.facebook.react.bridge.Promise) {
      val activity = reactApplicationContext.currentActivity as? androidx.fragment.app.FragmentActivity
      if (activity == null) {
          promise.reject("NO_ACTIVITY", "Current activity is null or not a FragmentActivity")
          return
      }

      UiThreadUtil.runOnUiThread {
          val executor = ContextCompat.getMainExecutor(activity)
          val biometricPrompt = BiometricPrompt(activity, executor,
              object : BiometricPrompt.AuthenticationCallback() {
                  override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                      super.onAuthenticationError(errorCode, errString)
                      promise.resolve(false)
                  }

                  override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                      super.onAuthenticationSucceeded(result)
                      promise.resolve(true)
                  }

                  override fun onAuthenticationFailed() {
                      super.onAuthenticationFailed()
                      promise.resolve(false)
                  }
              })

          val promptInfo = BiometricPrompt.PromptInfo.Builder()
              .setTitle(promptMessage)
              .setNegativeButtonText("Cancel")
              .build()

          biometricPrompt.authenticate(promptInfo)
      }
  }

  override fun addSSLPinning(domain: String, publicKeyHashes: com.facebook.react.bridge.ReadableArray, promise: com.facebook.react.bridge.Promise) {
    try {
      val pinnerBuilder = okhttp3.CertificatePinner.Builder()
      for (i in 0 until publicKeyHashes.size()) {
        val hash = publicKeyHashes.getString(i)
        if (hash != null) {
          pinnerBuilder.add(domain, hash)
        }
      }
      val certificatePinner = pinnerBuilder.build()

      com.facebook.react.modules.network.OkHttpClientProvider.setOkHttpClientFactory {
        com.facebook.react.modules.network.OkHttpClientProvider.createClientBuilder()
          .certificatePinner(certificatePinner)
          .build()
      }
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject("SSL_PINNING_ERROR", e)
    }
  }

  override fun updateSSLPins(domain: String, publicKeyHashes: com.facebook.react.bridge.ReadableArray, promise: com.facebook.react.bridge.Promise) {
      // Overriding the factory again creates a new OkHttp client with the new pins
      addSSLPinning(domain, publicKeyHashes, promise)
  }

  override fun preventScreenshot(prevent: Boolean, promise: com.facebook.react.bridge.Promise) {
    val activity = currentActivity
    if (activity == null) {
      promise.reject("NO_ACTIVITY", "Current activity is null")
      return
    }

    activity.runOnUiThread {
      try {
        if (prevent) {
          activity.window.addFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
        } else {
          activity.window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
        }
        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("PREVENT_SCREENSHOT_ERROR", e)
      }
    }
  }

  // Secure Storage Implementation
  private fun getEncryptedSharedPreferences(): android.content.SharedPreferences {
    val masterKey = androidx.security.crypto.MasterKey.Builder(reactApplicationContext)
      .setKeyScheme(androidx.security.crypto.MasterKey.KeyScheme.AES256_GCM)
      .build()

    return androidx.security.crypto.EncryptedSharedPreferences.create(
      reactApplicationContext,
      "secret_shared_prefs",
      masterKey,
      androidx.security.crypto.EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
      androidx.security.crypto.EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )
  }

  override fun setSecureString(key: String, value: String, promise: com.facebook.react.bridge.Promise) {
    try {
      getEncryptedSharedPreferences().edit().putString(key, value).apply()
      promise.resolve(true)
    } catch (e: Exception) {
      promise.reject("SECURE_STORAGE_ERROR", e)
    }
  }

  override fun getSecureString(key: String, promise: com.facebook.react.bridge.Promise) {
    try {
      val value = getEncryptedSharedPreferences().getString(key, null)
      promise.resolve(value)
    } catch (e: Exception) {
      promise.reject("SECURE_STORAGE_ERROR", e)
    }
  }

  override fun removeSecureString(key: String, promise: com.facebook.react.bridge.Promise) {
    try {
      getEncryptedSharedPreferences().edit().remove(key).apply()
      promise.resolve(true)
    } catch (e: Exception) {
      promise.reject("SECURE_STORAGE_ERROR", e)
    }
  }

  private fun checkRootMethod1(): Boolean {
    val buildTags = android.os.Build.TAGS
    return buildTags != null && buildTags.contains("test-keys")
  }

  private fun checkRootMethod2(): Boolean {
    val paths = arrayOf(
      "/system/app/Superuser.apk",
      "/sbin/su",
      "/system/bin/su",
      "/system/xbin/su",
      "/data/local/xbin/su",
      "/data/local/bin/su",
      "/system/sd/xbin/su",
      "/system/bin/failsafe/su",
      "/data/local/su",
      "/su/bin/su"
    )
    for (path in paths) {
      if (File(path).exists()) return true
    }
    return false
  }

  private fun checkRootMethod3(): Boolean {
    var process: Process? = null
    return try {
      process = Runtime.getRuntime().exec(arrayOf("/system/xbin/which", "su"))
      val inReader = BufferedReader(InputStreamReader(process.inputStream))
      inReader.readLine() != null
    } catch (t: Throwable) {
      false
    } finally {
      process?.destroy()
    }
  }

  companion object {
    const val NAME = "Shield"
  }
}
