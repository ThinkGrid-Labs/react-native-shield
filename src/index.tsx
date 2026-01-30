import Shield from './NativeShield';

export function isRooted(): boolean {
  return Shield.isRooted();
}

export function addSSLPinning(
  domain: string,
  publicKeyHashes: string[]
): Promise<void> {
  return Shield.addSSLPinning(domain, publicKeyHashes);
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
