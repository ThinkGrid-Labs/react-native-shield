# Secure Storage API

| Method | Returns | Description |
|---|---|---|
| `setSecureString(key, value)` | `Promise<boolean>` | Encrypt and store a string |
| `getSecureString(key)` | `Promise<string \| null>` | Decrypt and retrieve a stored string |
| `removeSecureString(key)` | `Promise<boolean>` | Delete a single key from secure storage |
| `getAllSecureKeys()` | `Promise<string[]>` | List all keys currently in secure storage |
| `clearAllSecureStorage()` | `Promise<boolean>` | Delete all keys from secure storage |

## `setSecureString(key, value)`

```typescript
setSecureString(key: string, value: string): Promise<boolean>
```

Resolves `true` on success.

## `getSecureString(key)`

```typescript
getSecureString(key: string): Promise<string | null>
```

Returns `null` if the key does not exist.

## `removeSecureString(key)`

```typescript
removeSecureString(key: string): Promise<boolean>
```

Resolves `true` on success, `false` if the key was not found.

## `getAllSecureKeys()`

```typescript
getAllSecureKeys(): Promise<string[]>
```

Returns all keys stored by this app. Scoped to the app's bundle ID on iOS and package name on Android.

## `clearAllSecureStorage()`

```typescript
clearAllSecureStorage(): Promise<boolean>
```

Deletes all keys. Safe to call when storage is already empty.
