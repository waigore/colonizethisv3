import 'dart:async';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

/// Retry VM service connect on cold Android emulators (Refs #4687).
///
/// `FlutterDriver.connect` can fail with `Sentinel kind: Collected` when the
/// isolate is still warming up after a slow AVD boot in CI.
Future<FlutterDriver> _connectWithRetry({
  int attempts = 6,
  Duration pause = const Duration(seconds: 10),
}) async {
  Object? lastError;
  StackTrace? lastStack;
  for (var i = 0; i < attempts; i++) {
    try {
      return await FlutterDriver.connect();
    } catch (e, st) {
      lastError = e;
      lastStack = st;
      stderr.writeln(
        'integration_driver: connect attempt ${i + 1}/$attempts failed: $e',
      );
      if (i < attempts - 1) {
        await Future<void>.delayed(pause);
      }
    }
  }
  Error.throwWithStackTrace(lastError!, lastStack ?? StackTrace.empty);
}

Future<void> main() async {
  final driver = await _connectWithRetry();
  await integrationDriver(driver: driver);
}
