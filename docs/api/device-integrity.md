# Device Integrity API

All methods are synchronous.

| Method | Returns | Description |
|---|---|---|
| `isRooted()` | `boolean` | `true` if device is rooted (Android) or jailbroken (iOS) |
| `isEmulator()` | `boolean` | `true` if running in a simulator or emulator |
| `isDebuggerAttached()` | `boolean` | `true` if a debugger is attached to the process |
| `isDeveloperModeEnabled()` | `boolean` | `true` if ADB/developer options are active (Android only; always `false` on iOS) |
| `isHooked()` | `boolean` | `true` if Frida, Xposed, Substrate, or similar is detected |
| `verifySignature(hash)` | `boolean` | `true` if the app's signing cert SHA-256 matches `hash` |
| `getRootReasons()` | `string[]` | Array of reason codes explaining why the device is flagged |

## `verifySignature(hash)`

```typescript
verifySignature(hash: string): boolean
```

`hash` — expected SHA-256 fingerprint of your signing certificate (hex string, no colons).

Returns `false` if the APK has been repackaged with a different key, or if the app is running on iOS (where signature verification uses provisioning profiles rather than cert hashes).

## `getRootReasons()`

```typescript
getRootReasons(): string[]
```

Returns an empty array `[]` on clean devices. Possible values: `build_tags`, `su_binary`, `su_command`, `dangerous_packages`, `mount_flags` (Android); `jailbreak_files`, `sandbox_escape`, `cydia_scheme`, `substrate_loaded` (iOS).

See [Device Integrity guide](/guide/device-integrity#root--jailbreak-reason-codes) for full descriptions.
