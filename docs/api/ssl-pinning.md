# SSL Pinning API

| Method | Returns | Description |
|---|---|---|
| `addSSLPinning(domain, hashes)` | `Promise<void>` | Enable certificate pinning for a domain |
| `updateSSLPins(domain, hashes)` | `Promise<void>` | Update pins at runtime (Android only) |

## `addSSLPinning(domain, hashes)`

```typescript
addSSLPinning(domain: string, hashes: string[]): Promise<void>
```

**Parameters:**
- `domain` — hostname to pin (e.g. `"api.yourdomain.com"`)
- `hashes` — array of `sha256/` prefixed public key hashes (base64-encoded)

Must be called before any network requests to that domain. Always provide at least one backup hash.

## `updateSSLPins(domain, hashes)`

```typescript
updateSSLPins(domain: string, hashes: string[]): Promise<void>
```

**Android:** updates the OkHttp `CertificatePinner` immediately at runtime.

**iOS:** rejects with error code `SSL_PIN_UPDATE_UNSUPPORTED` — TrustKit locks its configuration at startup. Ship an app update to rotate iOS pins.
