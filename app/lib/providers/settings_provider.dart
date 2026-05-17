import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/desktop_window_settings.dart';

class SettingsNotifier extends Notifier<Map<String, Object?>> {
  @override
  Map<String, Object?> build() {
    if (!Hive.isBoxOpen(HiveBoxNames.settings)) {
      return const {};
    }
    final box = Hive.box<dynamic>(HiveBoxNames.settings);
    final startupMaximized =
        box.get(DesktopWindowSettingsKeys.startupMaximized) as bool? ?? true;
    box.put(DesktopWindowSettingsKeys.startupMaximized, startupMaximized);
    final next = <String, Object?>{
      for (final key in box.keys) key.toString(): box.get(key),
    };
    next[DesktopWindowSettingsKeys.startupMaximized] = startupMaximized;
    return next;
  }

  void replaceAll(Map<String, Object?> next) {
    state = next;
    if (Hive.isBoxOpen(HiveBoxNames.settings)) {
      final box = Hive.box<dynamic>(HiveBoxNames.settings);
      box.putAll(next);
    }
  }

  void setValue(String key, Object? value) {
    state = {...state, key: value};
    if (Hive.isBoxOpen(HiveBoxNames.settings)) {
      Hive.box<dynamic>(HiveBoxNames.settings).put(key, value);
    }
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Map<String, Object?>>(
      SettingsNotifier.new,
    );
