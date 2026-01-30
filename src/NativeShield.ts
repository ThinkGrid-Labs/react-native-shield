import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface Spec extends TurboModule {
  isRooted(): boolean;
  addSSLPinning(domain: string, publicKeyHashes: string[]): Promise<void>;
  preventScreenshot(prevent: boolean): Promise<void>;
  setSecureString(key: string, value: string): Promise<boolean>;
  getSecureString(key: string): Promise<string | null>;
  removeSecureString(key: string): Promise<boolean>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('Shield');
