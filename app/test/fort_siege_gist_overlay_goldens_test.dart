// Pixel goldens for MAP20001 Military fort siege gist (Refs #4764).
// SPEC/ui/province-sea-zone-detail-overlay.md § Fort siege gist.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fort_siege_gist_overlay_test_support.dart';
import 'golden_capture_harness.dart';
import 'province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpOverlayGolden(
    WidgetTester tester, {
    required Key boundaryKey,
    required int fortLevel,
    required Size physicalSize,
    required double overlayWidth,
  }) async {
    await configureGoldenSurface(tester, size: physicalSize);
    configureGoldenView(
      tester,
      physicalSize: physicalSize,
      devicePixelRatio: 1.0,
    );
    final game = fortSiegeOverlayGame(fortLevel: fortLevel);
    await tester.pumpWidget(
      wrapGoldenBoundary(
        boundaryKey: boundaryKey,
        includeLocalizations: true,
        child: SizedBox(
          width: overlayWidth,
          height: 900,
          child: buildProvinceOverlayDarkThemeShell(
            game: game,
            displayId: kFortSiegeOverlayProvinceId,
            region: fortSiegeOverlayRegion(),
            selectedTileKey: kFortSiegeOverlayTileKey,
            humanPlayerId: kFortSiegeOverlayHumanId,
            playerView: demoOverlayPlayerView(game),
            omniscientDetail: true,
            shellWidth: overlayWidth,
          ),
        ),
      ),
    );
    await pumpForGolden(tester);
  }

  testWidgets('golden: overlay wood fort siege gist (Refs #4764)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('fortSiegeGistOverlayWood');
    await pumpOverlayGolden(
      tester,
      boundaryKey: boundaryKey,
      fortLevel: 1,
      physicalSize: const Size(600, 1000),
      overlayWidth: 460,
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Wood fort siege'), findsOneWidget);
    expect(
      find.text(
        'Light walls soak some of the attack; the defender has 1 extra gun.',
      ),
      findsOneWidget,
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/fort_siege_gist_overlay_wood.png'),
    );
  });

  testWidgets(
    'golden: overlay wood fort siege gist wraps at 320 dp (Refs #4764)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('fortSiegeGistOverlayWood320');
      await pumpOverlayGolden(
        tester,
        boundaryKey: boundaryKey,
        fortLevel: 1,
        physicalSize: const Size(kMinViewportWidth, 1000),
        overlayWidth: kMinViewportWidth,
      );
      final militaryTab = find.text('Military');
      if (militaryTab.evaluate().isNotEmpty) {
        await tester.ensureVisible(militaryTab);
        await tester.tap(militaryTab);
        await pumpForGolden(tester);
      }
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Light walls soak some of the attack; the defender has 1 extra gun.',
        ),
        findsOneWidget,
      );
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/fort_siege_gist_overlay_wood_320.png'),
      );
    },
  );
}
