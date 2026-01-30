module.exports = {
  preset: 'react-native',
  modulePathIgnorePatterns: [
    '<rootDir>/example/node_modules',
    '<rootDir>/lib/',
  ],
  transform: {
    '^.+\\.(js|jsx|ts|tsx)$': [
      'babel-jest',
      { configFile: './babel.config.js' },
    ],
  },
  transformIgnorePatterns: [
    // deeply nested pnpm paths are tricky, let's try to include react-native explicitly
    'node_modules/(?!(\\.pnpm|.*react-native.*|@react-native.*)/)',
  ],
};
