module.exports = function (api) {
  api.cache(true);

  if (process.env.NODE_ENV === 'test') {
    return {
      presets: ['module:@react-native/babel-preset'],
    };
  }

  return {
    overrides: [
      {
        exclude: /\/node_modules\//,
        presets: ['module:react-native-builder-bob/babel-preset'],
      },
      {
        include: /\/node_modules\//,
        presets: ['module:@react-native/babel-preset'],
      },
    ],
  };
};
