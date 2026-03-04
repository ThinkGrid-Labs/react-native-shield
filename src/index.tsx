import Shield from './NativeShield';

export function isRooted(): boolean {
  return Shield.isRooted();
}

export function isEmulator(): boolean {
  return Shield.isEmulator();
}

export function isDebuggerAttached(): boolean {
  return Shield.isDebuggerAttached();
}

export function verifySignature(expectedHash: string): boolean {
  return Shield.verifySignature(expectedHash);
}

export function isHooked(): boolean {
  return Shield.isHooked();
}

export function isDeveloperModeEnabled(): boolean {
  return Shield.isDeveloperModeEnabled();
}

export function isVPNDetected(): boolean {
  return Shield.isVPNDetected();
}

export function protectClipboard(protect: boolean): Promise<void> {
  return Shield.protectClipboard(protect);
}

export function authenticateWithBiometrics(
  promptMessage: string
): Promise<boolean> {
  return Shield.authenticateWithBiometrics(promptMessage);
}

export function addSSLPinning(
  domain: string,
  publicKeyHashes: string[]
): Promise<void> {
  return Shield.addSSLPinning(domain, publicKeyHashes);
}

export function updateSSLPins(
  domain: string,
  publicKeyHashes: string[]
): Promise<void> {
  return Shield.updateSSLPins(domain, publicKeyHashes);
}

export function preventScreenshot(prevent: boolean): Promise<void> {
  return Shield.preventScreenshot(prevent);
}

export function setSecureString(key: string, value: string): Promise<boolean> {
  return Shield.setSecureString(key, value);
}

export function getSecureString(key: string): Promise<string | null> {
  return Shield.getSecureString(key);
}

export function removeSecureString(key: string): Promise<boolean> {
  return Shield.removeSecureString(key);
}
