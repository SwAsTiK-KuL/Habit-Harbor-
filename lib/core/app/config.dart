class AppConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  // API Configuration
  static String get apiBaseUrl {
    if (isProduction) {
      return 'https://your-production-api.com/api';
    } else {
      // Development configuration
      return _getDevBaseUrl();
    }
  }

  static String _getDevBaseUrl() {
    // Check if running on Android Emulator
    // You can also make this configurable via environment variables
    const bool useEmulatorUrl = bool.fromEnvironment(
      'USE_EMULATOR',
      defaultValue: false,
    );

    if (useEmulatorUrl) {
      return 'http://10.0.2.2:3001/api'; // Android Emulator - PORT 3001
    } else {
      return 'http://localhost:3001/api'; // iOS Simulator / Real Device - PORT 3001
    }
  }

  // Other configuration
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 30);
}
