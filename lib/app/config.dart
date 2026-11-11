abstract final class AppConfig {
  static const appName = 'PawPick';
  static const tagline = 'Little things. Big joy.';
  static const catalogVersion = 1;
  static const currencySymbol = '₱';
  static const currencyCode = 'PHP';
  static const freeShippingThresholdMinor = 250000;
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '840062807099-eedt7mkqlsa3c43lg753rn4gp76ofjpo.apps.googleusercontent.com',
  );
  static const supportEmail = 'hello@pawpick.example';
}
