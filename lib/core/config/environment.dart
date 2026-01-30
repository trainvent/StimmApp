enum EnvironmentType { dev, prod }

class Environment {
  static EnvironmentType type = EnvironmentType.prod; // Default to prod

  static void init(EnvironmentType t) {
    type = t;
  }

  static bool get isDev => type == EnvironmentType.dev;
  static bool get isProd => type == EnvironmentType.prod;
}
