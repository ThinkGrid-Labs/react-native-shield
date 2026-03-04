import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface Spec extends TurboModule {
  isRooted(): boolean;
  isEmulator(): boolean;
  isDebuggerAttached(): boolean;
  verifySignature(expectedHash: string): boolean;
  isHooked(): boolean;
  isDeveloperModeEnabled(): boolean;
  isVPNDetected(): boolean;
  protectClipboard(protect: boolean): Promise<void>;
  authenticateWithBiometrics(promptMessage: string): Promise<boolean>;
  addSSLPinning(domain: string, publicKeyHashes: string[]): Promise<void>;
  updateSSLPins(domain: string, publicKeyHashes: string[]): Promise<void>;
  preventScreenshot(prevent: boolean): Promise<void>;
  setSecureString(key: string, value: string): Promise<boolean>;
  getSecureString(key: string): Promise<string | null>;
  removeSecureString(key: string): Promise<boolean>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('Shield');
