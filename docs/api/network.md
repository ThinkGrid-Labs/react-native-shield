# Network & Environment API

| Method | Returns | Description |
|---|---|---|
| `isVPNDetected()` | `boolean` | `true` if traffic is routed through a VPN interface |
| `protectClipboard(protect)` | `Promise<void>` | Toggle auto-clear clipboard on app background |

## `isVPNDetected()`

```typescript
isVPNDetected(): boolean
```

Synchronous. Detects active VPN network interfaces. Does not detect manually configured HTTP proxies (see Roadmap v0.7.0).

## `protectClipboard(protect)`

```typescript
protectClipboard(protect: boolean): Promise<void>
```

When `protect` is `true`, the clipboard is cleared whenever the app transitions to the background.
