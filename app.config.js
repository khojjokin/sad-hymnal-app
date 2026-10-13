// app.json, with the build number the TestFlight workflow hands in (each upload needs a higher one).
module.exports = ({ config }) => ({
  ...config,
  ios: { ...config.ios, buildNumber: process.env.BUILD_NUMBER || config.ios.buildNumber || '1' },
  android: { ...config.android, versionCode: Number(process.env.BUILD_NUMBER || config.android.versionCode || 1) },
});
