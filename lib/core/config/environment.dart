enum EnvironmentType { dev, prod }

class Environment {
  static EnvironmentType type = EnvironmentType.prod; // Default to prod
  static const String _prodHost = 'stimmapp.eu';
  static const String _devHost = 'stimmapp-dev.web.app';

  static void init(EnvironmentType t) {
    type = t;
  }

  static bool get isDev => type == EnvironmentType.dev;
  static bool get isProd => type == EnvironmentType.prod;
  static String get shareHost => isDev ? _devHost : _prodHost;
  static String get shareBaseUrl => 'https://$shareHost';
}
