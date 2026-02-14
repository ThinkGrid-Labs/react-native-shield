# react-native-shield 🛡️

**The All-in-One Security Suite for React Native.**

`react-native-shield` provides a unified, easy-to-use API for essential mobile security features. Instead of managing multiple fragmented libraries for SSL pinning, root detection, and screenshot prevention, you get a single TurboModule package that "just works."

## Features

- **✅ Device Integrity**: Detect if a device is **Rooted** (Android) or **Jailbroken** (iOS).
- **🔒 SSL Pinning**: Secure your network requests against Man-in-the-Middle (MitM) attacks by pinning your server's public key.
- **🔑 Secure Storage**: Store sensitive tokens and keys in the device's secure hardware (Keychain/Keystore).
- **👁️ UI Privacy**: Prevent screenshots and screen recording, and automatically blur the app content when it goes into the background.
- **⚡ TurboModule**: Built on the New Architecture (Fabric/TurboModules) for optimal performance.

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
Don't forget to install the pods:
```sh
cd ios && pod install
```

---

## Usage

Import the library in your component:

```tsx
import { isRooted, addSSLPinning, preventScreenshot } from '@think-grid-labs/react-native-shield';
```

### 1. Device Integrity (Root/Jailbreak Detection)

Check if the device environment is safe.

```tsx
const checkIntegrity = () => {
  const unsafe = isRooted();
  if (unsafe) {
    console.warn("Security Alert: Device appears to be rooted or jailbroken.");
    // Handle accordingly: block sensitive actions, logout user, or show a warning.
  } else {
    console.log("Device is secure.");
  }
};
```

**What it checks:**
- **Android:** Looks for test-keys, `su` binary paths (standard and obscure), and dangerous apps like Superuser.
- **iOS:** Checks for common jailbreak files (Cydia, MobileSubstrate), ability to write outside sandbox, and unauthorized URL schemes.

### 2. SSL/Certificate Pinning

Prevent MitM attacks by verifying that the server's certificate public key matches your pins.

```tsx
// Call this EARLY in your app's lifecycle (e.g., in App.tsx)
useEffect(() => {
  const configureSecurity = async () => {
    try {
      await addSSLPinning('api.yourdomain.com', [
        'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // Backup Pin
        'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB='  // Primary Pin
      ]);
      console.log('SSL Pinning enabled for api.yourdomain.com');
    } catch (e) {
      console.error('Failed to configure SSL Pinning', e);
    }
  };

  configureSecurity();
}, []);
```

**How to get your Pin:**
You can specificy the SubjectPublicKeyInfo hash. A common way to get this is via openssl:
```sh
openssl s_client -servername api.yourdomain.com -connect api.yourdomain.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
```

### 3. UI Privacy (Screenshot Prevention)

Protect sensitive data from being captured.

```tsx
// Enable Privacy Mode
preventScreenshot(true);

// Disable Privacy Mode
preventScreenshot(false);
```

**Platform Behavior:**
- **Android:** Sets `WindowManager.LayoutParams.FLAG_SECURE`.
  - Prevents screenshots.
  - Prevents screen recording.
  - Hides app content in the "Recent Apps" switcher (shows black/white screen).
- **iOS:** 
  - **Screen Recording:** Masks the content using a hidden secure field layer (content appears hidden in recordings/mirroring).
  - **App Switcher:** Automatically blurs the application window when the app resigns active (goes to background), preventing sensitive data from being read in the multitasking view.
  - *Note: iOS does not allow complete prevention of system screenshots (Home+Power), but these measures significantly reduce exposure.*

### 4. Secure Storage

Store sensitive data (like auth tokens, API keys) securely.

```tsx
import { setSecureString, getSecureString, removeSecureString } from '@think-grid-labs/react-native-shield';

const manageSecrets = async () => {
    // 1. Save a secret
    const success = await setSecureString('user_token', 'xyz-123-abc');
    
    // 2. Retrieve a secret
    const token = await getSecureString('user_token'); // Returns 'xyz-123-abc' or null
    
    // 3. Delete a secret
    await removeSecureString('user_token');
};
```

**Implementation Details:**
- **Android:** Uses `EncryptedSharedPreferences` (part of `androidx.security.crypto`), utilizing the Master Key system for robust hardware-backed encryption.
- **iOS:** Uses **Keychain Services** (`SecItemAdd`, `SecItemCopyMatching`) to store data securely in the system keychain.

---

## API Reference

| Method | Type | Description |
| :--- | :--- | :--- |
| `isRooted()` | `() => boolean` | Synchronously returns `true` if the device is compromised. |
| `addSSLPinning()` | `(domain: string, hashes: string[]) => Promise<void>` | Configures the native network stack to strictly validate certificates for the given domain. |
| `preventScreenshot()` | `(prevent: boolean) => Promise<void>` | Toggles UI protection features on/off. |
| `setSecureString()` | `(key: string, value: string) => Promise<boolean>` | Encrypts and saves a string to secure storage. |
| `getSecureString()` | `(key: string) => Promise<string \| null>` | Decrypts and retrieves a string from secure storage. |
| `removeSecureString()` | `(key: string) => Promise<boolean>` | Deletes a string from secure storage. |

---

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
