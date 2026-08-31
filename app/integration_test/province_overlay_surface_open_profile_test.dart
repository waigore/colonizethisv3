import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/foundation.dart' show kProfileMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/province_overlay_open_path_timing_fixture.dart';
import '../test/province_sea_zone_overlay_detail_paths_support.dart';

/// Profile/release open-to-interactive measurement for MAP20001 (Refs #4690).
///
/// **Linux desktop binding host:**
/// `cd app && xvfb-run -a flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/province_overlay_surface_open_profile_test.dart \
///   --profile -d linux`
///
/// **Android emulator binding host:**
/// `cd app && flutter emulators --launch <avd_name>`
/// `flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/province_overlay_surface_open_profile_test.dart \
///   --profile -d <emulator_device_id>`
///
/// Or from repo root: `tool/run_ui_surface_profile_evidence.sh provinceOverlay`
///
/// Attach `ui_surface_open surface=provinceOverlay … host=linux_desktop_profile` or
/// `host=android_emulator_profile` from drive output / logcat for PR evidence.
void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpOverlayReady(WidgetTester tester) async {
    final binding = tester.view;
    final oldSize = binding.physicalSize;
    final oldRatio = binding.devicePixelRatio;
    addTearDown(() {
      binding.physicalSize = oldSize;
      binding.devicePixelRatio = oldRatio;
    });
    binding.physicalSize = const Size(400, 2000);
    binding.devicePixelRatio = 1.0;

    final fixture = ProvinceOverlayOpenPathTimingFixture.build();
    final region = demoRegionForOverlay;
    final selection = firstRevealedLandOverlaySelection(
      game: fixture.game,
      region: region,
    );
    expect(selection.selectedTileKey, isNotNull);

    await tester.pumpWidget(
      buildProvinceSeaZoneOverlayPathShell(
        game: fixture.game,
        region: region,
        displayId: selection.provinceId,
        humanPlayerId: fixture.game.players.first.id,
        selectedTileKey: selection.selectedTileKey,
      ),
    );
    await tester.pump();
    await tester.pump();

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.provinceOverlay_titleProvince), findsOneWidget);
    expect(find.text(l10n.provinceOverlay_sectionPolitical), findsOneWidget);
  }

  testWidgets(
    'MAP20001 interactiveReady within 1s on profile/release binding host',
    (WidgetTester tester) async {
      await pumpOverlayReady(tester);

      final elapsedMs = ctAppPerfSurfaceOpenElapsedMs('provinceOverlay');
      expect(elapsedMs, isNotNull);

      if (kProfileMode || kReleaseMode) {
        expect(
          elapsedMs!,
          lessThanOrEqualTo(kUiSurfaceOpenBudgetMs),
          reason:
              'MAP20001 open-to-interactive exceeded $kUiSurfaceOpenBudgetMs ms',
        );
      }
    },
  );

  testWidgets(
    'MAP20001 same-turn re-open interactiveReady within 1s on profile/release',
    (WidgetTester tester) async {
      await pumpOverlayReady(tester);
      expect(ctAppPerfSurfaceOpenElapsedMs('provinceOverlay'), isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await pumpOverlayReady(tester);
      final warmMs = ctAppPerfSurfaceOpenElapsedMs('provinceOverlay');
      expect(warmMs, isNotNull);
      if (kProfileMode || kReleaseMode) {
        expect(
          warmMs!,
          lessThanOrEqualTo(kUiSurfaceOpenBudgetMs),
        );
      }
    },
  );
}
