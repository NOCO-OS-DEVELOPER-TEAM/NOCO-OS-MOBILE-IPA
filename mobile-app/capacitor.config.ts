import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'de.noco.ai',
  appName: 'NOCO AI',
  webDir: 'www',
  ios: {
    contentInset: 'always',
    backgroundColor: '#0a0f1a',
    preferredContentMode: 'mobile',
    scrollEnabled: false
  },
  server: {
    androidScheme: 'https'
  }
};

export default config;
