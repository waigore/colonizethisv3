import 'package:colonizethis_app/providers/settings_provider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  test('settingsProvider replaceAll and setValue update settings map', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(settingsProvider.notifier);
    expect(container.read(settingsProvider), isEmpty);

    notifier.replaceAll(const {'musicVolume': 8});
    expect(container.read(settingsProvider), const {'musicVolume': 8});

    notifier.setValue('musicVolume', 10);
    notifier.setValue('language', 'en');
    expect(
      container.read(settingsProvider),
      const {'musicVolume': 10, 'language': 'en'},
    );
  });
}
