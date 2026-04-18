import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub provider for user settings. Phase 0: no real state; Phase 1+ wires to Hive.
class SettingsNotifier extends Notifier<Map<String, Object?>> {
  @override
  Map<String, Object?> build() => const {};

  void replaceAll(Map<String, Object?> next) {
    state = next;
  }

  void setValue(String key, Object? value) {
    state = {...state, key: value};
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Map<String, Object?>>(
      SettingsNotifier.new,
    );
