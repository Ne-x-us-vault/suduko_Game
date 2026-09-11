/// Minimal diagnostic logging abstraction.
///
/// Development builds may emit verbose diagnostics; release builds stay quiet.
/// Nothing sensitive is ever logged by design.
library;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class LogService {
  static bool verbose = kDebugMode;

  static void debug(String message) {
    if (verbose) _log(LogLevel.debug, message);
  }

  static void info(String message) {
    if (verbose) _log(LogLevel.info, message);
  }

  static void warning(String message) {
    _log(LogLevel.warning, message);
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    _log(LogLevel.error, message);
    if (verbose && error != null) {
      debug('  cause: $error');
      if (stack != null) debug('  stack: ${stack.toString().split('\n').take(6).join('\n')}');
    }
  }

  static void _log(LogLevel level, String message) {
    // ignore: avoid_print
    print('[QUEENS][${level.name}] $message');
  }
}