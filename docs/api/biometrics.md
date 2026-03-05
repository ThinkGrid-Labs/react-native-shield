# Biometrics API

| Method | Returns | Description |
|---|---|---|
| `authenticateWithBiometrics(prompt)` | `Promise<boolean>` | Launches native biometric prompt; resolves `true` on success |
| `getBiometricStrength()` | `Promise<"strong" \| "weak" \| "none">` | Returns the strength level of enrolled biometrics |

## `authenticateWithBiometrics(prompt)`

```typescript
authenticateWithBiometrics(prompt: string): Promise<boolean>
```

**Parameters:**
- `prompt` — string shown in the native biometric dialog (e.g. `"Authenticate to continue"`)

**Resolves** `true` on successful authentication, `false` if the user cancels or fails.

## `getBiometricStrength()`

```typescript
getBiometricStrength(): Promise<"strong" | "weak" | "none">
```

| Value | Meaning |
|---|---|
| `"strong"` | Secure enclave-backed: Face ID, fingerprint (iOS), Class 3 biometric (Android) |
| `"weak"` | 2D camera-based: Face Unlock (Android) |
| `"none"` | No biometrics enrolled |
