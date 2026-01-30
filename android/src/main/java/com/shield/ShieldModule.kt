package com.shield

import com.facebook.react.bridge.ReactApplicationContext
import java.io.File
import java.io.BufferedReader
import java.io.InputStreamReader

class ShieldModule(reactContext: ReactApplicationContext) :
  NativeShieldSpec(reactContext) {

  override fun isRooted(): Boolean {
    return checkRootMethod1() || checkRootMethod2() || checkRootMethod3()
  }

  override fun addSSLPinning(domain: String, publicKeyHashes: com.facebook.react.bridge.ReadableArray, promise: com.facebook.react.bridge.Promise) {
    try {
      val pinnerBuilder = okhttp3.CertificatePinner.Builder()
      for (i in 0 until publicKeyHashes.size()) {
        pinnerBuilder.add(domain, publicKeyHashes.getString(i))
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
    const val NAME = NativeShieldSpec.NAME
  }
}
