// Widget goldens for #4140 visual AC: DLG90001 Settings idle-civilian warn
// toggle (`ux.warnIdleCiviliansOnEndTurn`). Pixel baselines under
// `app/test/goldens/` close the verify-github-issue UI proof gap.
//
// AC mapping:
//  - AC9: Settings exposes gameplay warn toggle with immediate apply
//
// SPEC: SPEC/ui/settings-dialog.md (DLG90001).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/config/ux_settings_keys.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_catalog_loader.dart';
import 'package:colonizethis_app/features/shell/settings/settings_dialog.dart';
import 'package:colonizethis_app/providers/settings_provider.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';

void main() {
  suppressLogsForTests();

  tearDown(() {
    MapThemeCatalogLoader.resetForTest();
  });

  testWidgets(
    'golden: DLG90001 Settings gameplay warn toggle (Refs #4140 AC9)',
    (WidgetTester tester) async {
      await MapThemeCatalogLoader.ensureLoaded();

      const boundaryKey = ValueKey<String>('settings_dialog_warn_toggle_golden');

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(420, 520),
        settle: false,
        includeLocalizations: true,
        wrapInProviderScope: true,
        overrides: <Override>[
          settingsProvider.overrideWith(
            () => _WarnToggleSettingsNotifier({
              UxSettingsKeys.warnIdleCiviliansOnEndTurn: true,
            }),
          ),
        ],
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: const SettingsDialog(),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.byKey(SettingsDialog.warnIdleCiviliansToggleKey), findsOneWidget);
      expect(find.byType(CtToggleSwitch), findsOneWidget);
      expect(
        find.text('Warn when civilians have no work order on end turn'),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/settings_dialog_warn_toggle.png'),
      );
    },
  );
}

class _WarnToggleSettingsNotifier extends SettingsNotifier {
  _WarnToggleSettingsNotifier(this._initial);

  final Map<String, Object?> _initial;

  @override
  Map<String, Object?> build() => _initial;
}
