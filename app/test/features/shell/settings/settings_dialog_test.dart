import 'dart:io';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_catalog_loader.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_models.dart';
import 'package:colonizethis_app/features/shell/settings/settings_dialog.dart';
import 'package:colonizethis_app/providers/settings_provider.dart';
import 'package:colonizethis_app/config/ux_settings_keys.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../../../app_shell_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  suppressLogsForTests();

  tearDown(() {
    MapThemeCatalogLoader.resetForTest();
  });

  testWidgets('Settings dialog shows multi-theme pickers only', (tester) async {
    await MapThemeCatalogLoader.ensureLoaded();

    await tester.pumpWidget(
      buildAppShell(
        child: const SizedBox(
          width: 400,
          height: 600,
          child: SettingsDialog(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(SettingsDialog.titleKey), findsOneWidget);
    expect(find.byKey(SettingsDialog.warnIdleCiviliansToggleKey), findsOneWidget);
    expect(find.byType(CtToggleSwitch), findsOneWidget);
    expect(find.byType(CtDropdown<String>), findsNWidgets(2));
    expect(
      find.byKey(SettingsDialog.groupDropdownKey(MapThemeGroupId.terrain)),
      findsOneWidget,
    );
    expect(
      find.byKey(
        SettingsDialog.groupDropdownKey(MapThemeGroupId.civilianIcons),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(SettingsDialog.groupDropdownKey(MapThemeGroupId.townIcons)),
      findsNothing,
    );
  });

  test(
    'settingsProvider setValue persists warnIdleCiviliansOnEndTurn in Hive',
    () async {
      final dir = await Directory.systemTemp.createTemp('ct_settings_warn_');
      Hive.init(dir.path);
      final box = await Hive.openBox<dynamic>(HiveBoxNames.settings);
      addTearDown(() async {
        await box.close();
        await Hive.deleteBoxFromDisk(HiveBoxNames.settings);
        await dir.delete(recursive: true);
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(settingsProvider.notifier)
          .setValue(UxSettingsKeys.warnIdleCiviliansOnEndTurn, false);
      expect(
        container.read(settingsProvider)[UxSettingsKeys.warnIdleCiviliansOnEndTurn],
        isFalse,
      );
      expect(box.get(UxSettingsKeys.warnIdleCiviliansOnEndTurn), isFalse);
    },
  );

  test(
    'settingsProvider setValue persists mapTheme.terrain in Hive',
    () async {
      final dir = await Directory.systemTemp.createTemp('ct_settings_dlg_');
      Hive.init(dir.path);
      await Hive.openBox<dynamic>(HiveBoxNames.settings);
      addTearDown(() async {
        await Hive.close();
        await dir.delete(recursive: true);
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(settingsProvider.notifier)
          .setValue(MapThemeGroupId.terrain.settingsKey, 'sepia');

      expect(
        container.read(settingsProvider)[MapThemeGroupId.terrain.settingsKey],
        'sepia',
      );
      expect(
        Hive.box<dynamic>(
          HiveBoxNames.settings,
        ).get(MapThemeGroupId.terrain.settingsKey),
        'sepia',
      );
    },
  );
}
