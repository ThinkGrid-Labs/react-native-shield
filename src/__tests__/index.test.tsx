import {
  isRooted,
  addSSLPinning,
  preventScreenshot,
  setSecureString,
  getSecureString,
  removeSecureString,
} from '../index';
import NativeShield from '../NativeShield';

// Prepare the mock
jest.mock('../NativeShield', () => {
  return {
    __esModule: true,
    default: {
      isRooted: jest.fn(),
      addSSLPinning: jest.fn(),
      preventScreenshot: jest.fn(),
      setSecureString: jest.fn(),
      getSecureString: jest.fn(),
      removeSecureString: jest.fn(),
    },
  };
});

describe('react-native-shield', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Device Integrity', () => {
    it('isRooted calls NativeShield.isRooted', () => {
      (NativeShield.isRooted as jest.Mock).mockReturnValue(true);
      expect(isRooted()).toBe(true);
      expect(NativeShield.isRooted).toHaveBeenCalledTimes(1);
    });
  });

  describe('SSL Pinning', () => {
    it('addSSLPinning calls NativeShield.addSSLPinning', async () => {
      const domain = 'example.com';
      const hashes = ['sha256/123'];
      (NativeShield.addSSLPinning as jest.Mock).mockResolvedValue(undefined);

      await addSSLPinning(domain, hashes);

      expect(NativeShield.addSSLPinning).toHaveBeenCalledWith(domain, hashes);
    });
  });

  describe('UI Privacy', () => {
    it('preventScreenshot(true) calls NativeShield.preventScreenshot', async () => {
      (NativeShield.preventScreenshot as jest.Mock).mockResolvedValue(
        undefined
      );
      await preventScreenshot(true);
      expect(NativeShield.preventScreenshot).toHaveBeenCalledWith(true);
    });

    it('preventScreenshot(false) calls NativeShield.preventScreenshot', async () => {
      (NativeShield.preventScreenshot as jest.Mock).mockResolvedValue(
        undefined
      );
      await preventScreenshot(false);
      expect(NativeShield.preventScreenshot).toHaveBeenCalledWith(false);
    });
  });

  describe('Secure Storage', () => {
    it('setSecureString pass correct arguments', async () => {
      (NativeShield.setSecureString as jest.Mock).mockResolvedValue(true);
      const result = await setSecureString('key', 'value');
      expect(result).toBe(true);
      expect(NativeShield.setSecureString).toHaveBeenCalledWith('key', 'value');
    });

    it('getSecureString returns stored value', async () => {
      (NativeShield.getSecureString as jest.Mock).mockResolvedValue('secret');
      const result = await getSecureString('key');
      expect(result).toBe('secret');
      expect(NativeShield.getSecureString).toHaveBeenCalledWith('key');
    });

    it('removeSecureString calls native remove', async () => {
      (NativeShield.removeSecureString as jest.Mock).mockResolvedValue(true);
      const result = await removeSecureString('key');
      expect(result).toBe(true);
      expect(NativeShield.removeSecureString).toHaveBeenCalledWith('key');
    });
  });
});
