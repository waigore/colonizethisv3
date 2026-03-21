import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:session_log_buffer/session_log_buffer.dart';

import 'app.dart';
import 'config/constants.dart';
import 'core/services/app_event_handler_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SessionLogBuffer.init();
  await Hive.initFlutter();
  try {
    await Hive.openBox(HiveBoxNames.settings);
    await Hive.openBox(HiveBoxNames.games);
    await Hive.openBox(HiveBoxNames.offlineQueue);
  } catch (_) {
    // Phase 0: stub wiring; boxes may be locked (e.g. another instance). App still runs.
  }
  runApp(const ProviderScope(child: AppEventHandlerScope(child: App())));
}
