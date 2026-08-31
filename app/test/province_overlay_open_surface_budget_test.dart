// Full-widget open-to-interactive profiling anchors for MAP20001 (Refs #4690).
//
// CI surrogate for profile/release DevTools sessions on binding hosts: measures
// pump-to-interactive on the seed-42 campaign fixture. Not a debug wall-clock
// 1s assertion — the standing 1 000 ms gate is profile/release on Linux
// desktop and Android emulator (see enforcement boundary in
// SPEC/ui/province-sea-zone-detail-overlay.md).

import 'package:colonizethis_app/providers/province_overlay_read_model_cache_provider.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_open_path_timing_fixture.dart';
import 'province_sea_zone_overlay_detail_paths_support.dart';

Future<int> _openToInteractiveMs(WidgetTester tester) async {
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

  final sw = Stopwatch()..start();
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
  sw.stop();
  return sw.elapsedMilliseconds;
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'cold open paints chrome and Political section (Refs #4690)',
    (WidgetTester tester) async {
      final elapsedMs = await _openToInteractiveMs(tester);
      expect(elapsedMs, greaterThan(0));
    },
  );

  testWidgets(
    'same-turn re-open completes interactive paint (Refs #4690)',
    (WidgetTester tester) async {
      await _openToInteractiveMs(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final warmMs = await _openToInteractiveMs(tester);
      expect(warmMs, greaterThan(0));
    },
  );

  test(
    'read-model cold open path median stays bounded on seed-42 fixture (Refs #4690)',
    () {
      const iterations = 20;
      final fixture = ProvinceOverlayOpenPathTimingFixture.build();
      final coldMicros = provinceOverlayOpenPathTimeMicrosMedian(
        () => buildProvinceOverlayProvinceReadModel(
          game: fixture.game,
          displayId: fixture.displayId,
          mapData: fixture.mapData,
        ),
        iterations: iterations,
      );
      expect(
        coldMicros,
        lessThan(500000),
        reason:
            'province read-model cold median ${coldMicros}µs over $iterations iterations',
      );
    },
  );
}
