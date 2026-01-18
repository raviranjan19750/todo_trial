import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

final loggerProvider = Provider<Logger>((ref) => Logger());

class Logger {
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(message, name: 'ERROR', error: error, stackTrace: stackTrace);
  }
}
