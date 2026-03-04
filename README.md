# react-native-shield 🛡️

**The All-in-One Security Suite for React Native.**

[![npm version](https://badge.fury.io/js/%40think-grid-labs%2Freact-native-shield.svg)](https://badge.fury.io/js/%40think-grid-labs%2Freact-native-shield)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

`react-native-shield` provides a unified, easy-to-use API for essential mobile security features. Instead of managing multiple fragmented libraries for SSL pinning, root detection, secure storage, and UI privacy, you get a single TurboModule package that "just works" on both Android and iOS.

## Features

- **✅ Device Integrity**: Detect if a device is **Rooted** (Android) or **Jailbroken** (iOS).
- **🕵️ Anti-Tampering**: Detect if the app is running in an **Emulator/Simulator**, or if a **Debugger** is attached to the process.
- **🔒 SSL Pinning**: Secure your network requests against Man-in-the-Middle (MitM) attacks by pinning your server's public key hash.
- **🔑 Secure Storage**: Store sensitive tokens and keys in the device's secure hardware (Keychain on iOS, EncryptedSharedPreferences on Android).
- **👁️ UI Privacy**: Prevent screenshots and screen recording. Automatically blur the app content when it goes into the background.
- **⚡ TurboModule API**: Built on the New Architecture (Fabric/TurboModules) for synchronous access and optimal performance.

---

## Installation

```sh
npm install @think-grid-labs/react-native-shield
# or
yarn add @think-grid-labs/react-native-shield
# or
pnpm add @think-grid-labs/react-native-shield
```

### iOS Setup
The iOS implementation relies on TrustKit for SSL Pinning. Make sure to install the CocoaPods dependencies:
```sh
cd ios && pod install
```

---

## Modules & Usage

Import the library functions into your component or app startup logic:

```typescript
import { 
  isRooted, 
  isEmulator,
  isDebuggerAttached,
  verifySignature,
  isHooked,
  isDeveloperModeEnabled,
  isVPNDetected,
  protectClipboard,
  authenticateWithBiometrics,
  addSSLPinning, 
  updateSSLPins,
  preventScreenshot, 
  setSecureString, 
  getSecureString, 
  removeSecureString 
} from '@think-grid-labs/react-native-shield';
```

### 1. Device Integrity & Anti-Tampering

Check if the device environment is safe from root access, emulation, or debugging. These use synchronous TurboModule calls for immediate results.

```typescript
const checkIntegrity = () => {
  if (isRooted()) {
    console.warn("Security Alert: Device appears to be rooted or jailbroken.");
    // Action to take: block sensitive actions, wipe data, or alert the user.
  }
  
  if (isEmulator()) {
    console.warn("Security Alert: App is running in an emulator.");
  }

  if (isDebuggerAttached()) {
    console.warn("Security Alert: Debugger attached. Potential reverse-engineering attempt.");
  }

  if (isDeveloperModeEnabled()) {
    console.warn("Security Alert: ADB/Developer Mode is enabled (Android).");
  }

  if (isHooked()) {
    console.warn("Security Alert: Injection framework detected (Frida/Xposed).");
  }

  // Supply your expected SHA-256 certificate hash (Android)
  if (!verifySignature("YOUR_EXPECTED_HASH")) {
    console.warn("Security Alert: App signature mismatch. Possible repackaging.");
  }
};
```

**Implementation Details:**
- **Root Detection:** 
  - *Android:* Looks for `test-keys` in build tags, `su` binary execution, and commonly known root directories.
  - *iOS:* Checks for common jailbreak files, verifies sandbox write limits, and checks for unauthorized URL schemes.
- **Emulator Detection:**
  - *Android:* Checks `Build.FINGERPRINT`, `Build.MODEL`, `Build.HARDWARE`, and `Build.PRODUCT` against known emulator signatures.
  - *iOS:* Checks the `TARGET_OS_SIMULATOR` macro at runtime.
- **Debugger Detection:**
  - *Android:* Queries `android.os.Debug.isDebuggerConnected()`.
  - *iOS:* Queries the kernel via `sysctl` to check if the `P_TRACED` flag is set on the current process.
- **App Signature Verification:**
  - *Android:* Hashes the `PackageManager` signing certificates (SHA-256) and compares them against the provided hash string.
  - *iOS:* Returns false if `embedded.mobileprovision` is present (meaning not tied to App Store), as deeper programmatic verification is heavily restrictive on iOS.
- **Hooking Detection:**
  - *Android:* Probes the classloader for Xposed and Substrate classes, and checks file paths for `frida-server`.
  - *iOS:* Scans registered `dyld` dynamic libraries for names like `Frida`, `Substrate`, `cycript`, or `SSLKillSwitch`.
- **Developer Mode Check:**
  - *Android:* Looks at `Settings.Global.DEVELOPMENT_SETTINGS_ENABLED` and `ADB_ENABLED`.
  - *iOS:* Not supported natively (always returns `false`).

### 2. App Environment Security

Protecting user interaction states and network paths.

```typescript
const protectAppEnvironment = () => {
  // Clear the clipboard string when the app goes into the background
  protectClipboard(true);

  if (isVPNDetected()) {
     console.warn("Network path is utilizing a VPN or proxy.");
  }
};
```

### 3. Biometric Authentication

Launch the platform's native biometric prompt (FaceID/TouchID/Android Biometrics) directly. This method uses a zero-dependency local implementation avoiding additional module bloat.

```typescript
const loginWithFaceID = async () => {
    const success = await authenticateWithBiometrics("Please authenticate to unlock secure data");
    if (success) {
      // Proceed to unlock
    } else {
      // Authentication failed or canceled
    }
};
```

### 4. SSL/Certificate Pinning

Prevent MitM attacks by verifying that the server's certificate public key matches your predefined pins.

```typescript
// Call this EARLY in your app's lifecycle (e.g., in App.tsx or index.js)
useEffect(() => {
  const configureSecurity = async () => {
    try {
      // Provide an array of base64 encoded SHA-256 public key hashes
      await addSSLPinning('api.yourdomain.com', [
        'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // Primary Pin
        'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB='  // Backup Pin
      ]);
      console.log('SSL Pinning enabled for api.yourdomain.com');

      // If pins rotate dynamically, pass new arrays
      await updateSSLPins('api.yourdomain.com', [
        'sha256/CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC='
      ]);
    } catch (e) {
      console.error('Failed to configure SSL Pinning', e);
    }
  };

  configureSecurity();
}, []);
```

**How to get your Pin:**
You must provide the SubjectPublicKeyInfo hash. You can extract this using OpenSSL:
```sh
openssl s_client -servername api.yourdomain.com -connect api.yourdomain.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
```

### 3. Secure Storage

Store sensitive data like authentication tokens or API keys securely using native encrypted abstractions.

```typescript
const manageSecrets = async () => {
    // Save a secret
    const success = await setSecureString('user_token', 'xyz-123-abc');
    
    // Retrieve a secret
    const token = await getSecureString('user_token'); // Returns 'xyz-123-abc' or null
    
    // Delete a secret
    await removeSecureString('user_token');
};
```

**Implementation Details:**
- **Android:** Powered by `androidx.security.crypto.EncryptedSharedPreferences`, utilizing the Android Keystore Master Key system (AES256_GCM).
- **iOS:** Powered by **Keychain Services** (`SecItemAdd`, `SecItemCopyMatching`) to store data securely inside the iOS secure enclave.

### 6. UI Privacy (Screenshot & Screen Recording Prevention)

Protect sensitive data from being captured by other apps, recordings, or the user.

```typescript
// Enable Privacy Mode
await preventScreenshot(true);

// Disable Privacy Mode
await preventScreenshot(false);
```

**Platform Behavior & Limitations:**
- **Android:** Sets `WindowManager.LayoutParams.FLAG_SECURE`.
  - Prevents physical screenshots and screen recording.
  - Automatically hides app content in the "Recent Apps" OS switcher (shows a black or white screen).
- **iOS:** Uses the `UITextField` secureTextEntry hack and background blurs.
  - **Screen Recording:** Masks the content using a hidden secure field layer. The content appears hidden in recordings or AirPlay mirroring.
  - **App Switcher:** Injects a blur effect when the app resigns active (goes to the background), preventing data leaks in the multitasking view.
  - ⚠️ **Known Limitation:** True hardware screenshot prevention (pressing Home+Power) is not officially supported by iOS. This module primarily blocks programmatic recording and hides data in the app switcher.
  - ⚠️ **Known Bug:** In the current implementation, calling `preventScreenshot(false)` removes background blurs but does *not* completely dismantle the screen-recording protection layer in the visual hierarchy. Re-rendering might be required.

---

## API Reference

| Method | Type | Description |
| :--- | :--- | :--- |
| `isRooted()` | `() => boolean` | Synchronously returns `true` if the device is compromised (rooted/jailbroken). |
| `isEmulator()` | `() => boolean` | Synchronously returns `true` if running in a Simulator/Emulator. |
| `isDebuggerAttached()` | `() => boolean` | Synchronously returns `true` if a debugger is actively attached to the process. |
| `isDeveloperModeEnabled()` | `() => boolean` | Synchronously checks if Developer Options/ADB are enabled (Android only). |
| `isHooked()` | `() => boolean` | Synchronously checks for hooked frameworks (Frida, Xposed, Substrate). |
| `verifySignature(hash)` | `(hash: string) => boolean` | Verifies the app's signing cert matches `hash` (Android) or is valid (iOS). |
| `isVPNDetected()` | `() => boolean` | Synchronously returns `true` if traffic is routed via VPN interfaces. |
| `protectClipboard(protect)`| `(protect: boolean) => Promise<void>` | Toggles auto-clearing the clipboard when UI enters the background. |
| `authenticateWithBiometrics(prompt)`| `(prompt: string) => Promise<boolean>` | Starts FaceID/TouchID/Android Biometrics prompt. Returns `true` on success. |
| `addSSLPinning(domain, hashes)`| `(domain: string, hashes: string[]) => Promise<void>` | Enforces strict validation of the public key for the specific domain natively. |
| `updateSSLPins(domain, hashes)`| `(domain: string, hashes: string[]) => Promise<void>` | Rotates hashes dynamically (*iOS TrustKit requires app restart to apply*). |
| `preventScreenshot(prevent)` | `(prevent: boolean) => Promise<void>` | Toggles UI protection features (recording prevention, background blur) on/off. |
| `setSecureString(key, value)` | `(key: string, value: string) => Promise<boolean>` | Encrypts and securely saves a string using Keystore/Keychain. |
| `getSecureString(key)` | `(key: string) => Promise<string \| null>` | Decrypts and retrieves a string from secure storage. |
| `removeSecureString(key)` | `(key: string) => Promise<boolean>` | Deletes a string securely from storage. |

---

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and set up the development workflow seamlessly.

## License

MIT
