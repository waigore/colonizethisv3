import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:session_log_buffer/session_log_buffer.dart';

import 'app.dart';
import 'config/constants.dart';
import 'core/services/app_event_handler_scope.dart';

final _log = Logger();

/// Opens one Hive box; failures are isolated so another box (e.g. games) still opens.
Future<void> _openHiveBoxSafely(String name) async {
  try {
    await Hive.openBox<dynamic>(name);
  } catch (e, st) {
    // Boxes may be locked (e.g. another instance) or corrupt; app still runs where possible.
    _log.w('data:hive: failed to open box "$name"', error: e, stackTrace: st);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SessionLogBuffer.init();
  await Hive.initFlutter();
  await _openHiveBoxSafely(HiveBoxNames.settings);
  await _openHiveBoxSafely(HiveBoxNames.games);
  await _openHiveBoxSafely(HiveBoxNames.offlineQueue);
  runApp(const ProviderScope(child: AppEventHandlerScope(child: App())));
}
