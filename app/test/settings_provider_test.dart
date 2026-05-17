import 'dart:io';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/desktop_window_settings.dart';
import 'package:colonizethis_app/providers/settings_provider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  suppressLogsForTests();

  test(
    'settingsProvider replaceAll and setValue update settings map',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'ct_settings_provider_',
      );
      Hive.init(dir.path);
      await Hive.openBox<dynamic>(HiveBoxNames.settings);
      addTearDown(() async {
        await Hive.close();
        await dir.delete(recursive: true);
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      expect(
        container.read(
          settingsProvider,
        )[DesktopWindowSettingsKeys.startupMaximized],
        isTrue,
      );

      notifier.replaceAll(const {'musicVolume': 8});
      expect(container.read(settingsProvider), const {'musicVolume': 8});

      notifier.setValue('musicVolume', 10);
      notifier.setValue('language', 'en');
      expect(container.read(settingsProvider), const {
        'musicVolume': 10,
        'language': 'en',
      });
      expect(Hive.box<dynamic>(HiveBoxNames.settings).get('musicVolume'), 10);
    },
  );
}
