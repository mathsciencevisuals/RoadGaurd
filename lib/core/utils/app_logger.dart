import 'dart:developer' as developer;

class AppLogger {
  AppLogger._();

  static void info(String message) {
    developer.log(message, name: 'RoadGuard');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'RoadGuard',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
