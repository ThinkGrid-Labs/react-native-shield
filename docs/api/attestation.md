# Platform Attestation API

| Method | Returns | Description |
|---|---|---|
| `requestIntegrityToken(nonce)` | `Promise<string>` | Play Integrity token (Android) or DeviceCheck token (iOS) |

## `requestIntegrityToken(nonce)`

```typescript
requestIntegrityToken(nonce: string): Promise<string>
```

**Parameters:**
- `nonce` — server-generated, single-use random value (minimum 16 bytes, base64-encoded)

**Resolves** with a signed token string to send to your backend for verification.

**Rejects** with:
- `INTEGRITY_NOT_SUPPORTED` — running on an emulator, unsigned build, or device without Play Services
- `INTEGRITY_ERROR` — network error or Play Services unavailable

See the [Attestation guide](/guide/attestation) for server-side verification details.
