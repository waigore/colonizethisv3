// Widget goldens for OVL20001 calendar-complete variant (Refs #4483).
// SPEC: SPEC/ui/victory-overlay.md § States and variants / ACs.
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/overlays/victory_overlay.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late ct_models.AppEventBus bus;

  setUp(() {
    ct_models.AppEventBus.reset();
    bus = ct_models.AppEventBus.create();
  });

  tearDown(() {
    ct_models.AppEventBus.reset();
  });

  Future<void> pumpCalendarOverlayGolden(
    WidgetTester tester, {
    required Key boundaryKey,
    required ct_models.Game game,
    required Size size,
  }) async {
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: size,
      includeLocalizations: true,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            ColoredBox(color: const Color(0xFF1A1510)),
            VictoryOverlay(game: game, bus: bus),
          ],
        ),
      ),
    );
  }

  testWidgets('golden: calendar complete declared winner', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('victoryOverlayCalendarWinner');
    await pumpCalendarOverlayGolden(
      tester,
      boundaryKey: boundaryKey,
      game: buildVictoryCalendarDeclaredWinnerTestGame(),
      size: const Size(460, 640),
    );
    expect(find.text('CAMPAIGN COMPLETE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/victory_overlay_calendar_declared_winner.png'),
    );
  });

  testWidgets('golden: calendar complete tie', (WidgetTester tester) async {
    const boundaryKey = ValueKey<String>('victoryOverlayCalendarTie');
    await pumpCalendarOverlayGolden(
      tester,
      boundaryKey: boundaryKey,
      game: buildVictoryCalendarTieTestGame(),
      size: const Size(460, 640),
    );
    expect(
      find.textContaining('no declared winner'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/victory_overlay_calendar_tie.png'),
    );
  });

  testWidgets('golden: calendar complete 320 dp', (WidgetTester tester) async {
    const boundaryKey = ValueKey<String>('victoryOverlayCalendar320');
    await pumpCalendarOverlayGolden(
      tester,
      boundaryKey: boundaryKey,
      game: buildVictoryCalendarDeclaredWinnerTestGame(),
      size: const Size(kMinViewportWidth, 640),
    );
    expect(find.text('CAMPAIGN COMPLETE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/victory_overlay_calendar_320dp.png'),
    );
  });
}
