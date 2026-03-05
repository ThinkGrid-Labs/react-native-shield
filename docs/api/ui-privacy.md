# UI Privacy API

| Method | Returns | Description |
|---|---|---|
| `preventScreenshot(prevent)` | `Promise<void>` | Toggle screenshot/recording prevention and background blur |

## `preventScreenshot(prevent)`

```typescript
preventScreenshot(prevent: boolean): Promise<void>
```

**Parameters:**
- `prevent` — `true` to enable protection, `false` to disable

**Android:** sets or clears `FLAG_SECURE` on the window, blocking screenshots and screen recording at the OS level.

**iOS:** applies a `UITextField.secureTextEntry` layer trick to mask screen recording and AirPlay mirroring, and injects a blur overlay on `WillResignActive` to hide content in the app switcher. Hardware screenshots (Home + Power) cannot be blocked.
