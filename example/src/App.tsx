import React from 'react';
import { Text, View, StyleSheet } from 'react-native';
import {
  isRooted,
  preventScreenshot,
  setSecureString,
  getSecureString,
} from 'react-native-shield';

const result = isRooted();

// Example Pinning (would normally be called early in app lifecycle)
// addSSLPinning('google.com', ['sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=']);

export default function App() {
  const [storageStatus, setStorageStatus] = React.useState(
    'Storage: Waiting...'
  );

  React.useEffect(() => {
    preventScreenshot(true);

    // Test Secure Storage
    const testStorage = async () => {
      try {
        await setSecureString('api_token', 'secret_12345');
        const val = await getSecureString('api_token');
        setStorageStatus(`Storage: Stored 'secret_12345', Retrieved '${val}'`);
      } catch {
        setStorageStatus('Storage: Failed');
      }
    };
    testStorage();
  }, []);

  return (
    <View style={styles.container}>
      <Text>Is Device Rooted/Jailbroken? {result ? 'YES' : 'NO'}</Text>
      <Text style={styles.text}>Privacy Mode: ACTIVE</Text>
      <Text style={styles.text}>{storageStatus}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  text: {
    marginTop: 20,
  },
});
