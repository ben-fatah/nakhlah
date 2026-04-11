import 'package:logger/logger.dart';

// ignore_for_file: non_constant_identifier_names

/// Application-wide logger.
///
/// Wraps the `logger` package so that import paths and configuration are
/// centralised. In release builds you can swap the printer for a no-op or
/// remote logging backend without touching call-sites.
final AppLogger = _createLogger();

Logger _createLogger() {
  return Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.debug,
  );
}
