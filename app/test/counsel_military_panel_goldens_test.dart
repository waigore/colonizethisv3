// Widget goldens for the Counsel Military tab (GAME90001) visual acceptance
// criteria (Refs #4307). Pixel baselines live under `app/test/goldens/`.
//
// Golden mapping:
//  - AC actionable lines: default Military tab with ≤3 recommendation cards
//  - AC stars / deep-link: highlight emphasizes focused card
//  - AC empty state: "No pressing military advice this turn."
//  - AC read-only: turn-resolution blocking hides Agree controls
//
// SPEC: SPEC/ui/counsel-panel.md § Military tab.

import 'package:colonizethis_app/features/game/screens/counsel/counsel_military_tab_body.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'counsel_military_panel_test_support.dart';
import 'golden_capture_harness.dart';

void main() {
  suppressLogsForTests();

  final stubCallbacks = CounselMilitaryCallbacks(
    onAgreeTrain: _noopTrain,
    onAgreeInvade: _noopInvade,
  );

  Future<void> pumpCounselMilitaryGolden(
    WidgetTester tester, {
    required Key boundaryKey,
    required Widget child,
  }) async {
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: kCounselMilitaryPanelGoldenViewport,
      includeLocalizations: true,
      center: false,
      child: child,
    );
  }

  testWidgets(
    'golden: Military tab default with three recommendations (Refs #4307)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('counselMilitaryPanelDefaultGolden');
      await pumpCounselMilitaryGolden(
        tester,
        boundaryKey: boundaryKey,
        child: counselMilitaryTabGoldenHost(
          recommendations: counselTestDefaultMilitaryRecommendations(),
          callbacks: stubCallbacks,
        ),
      );

      expect(find.text('Military'), findsOneWidget);
      expect(find.text('Agree'), findsNWidgets(3));
      expect(find.text('★'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/counsel_military_panel_default.png'),
      );
    },
  );

  testWidgets(
    'golden: Military tab highlight emphasizes focused card (Refs #4307)',
    (WidgetTester tester) async {
      const boundaryKey =
          ValueKey<String>('counselMilitaryPanelHighlightGolden');
      await pumpCounselMilitaryGolden(
        tester,
        boundaryKey: boundaryKey,
        child: counselMilitaryTabGoldenHost(
          recommendations: counselTestDefaultMilitaryRecommendations(),
          highlightRecommendationId: 'train:peasant_levies',
          callbacks: stubCallbacks,
        ),
      );

      expect(find.text('Agree'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/counsel_military_panel_highlight.png'),
      );
    },
  );

  testWidgets(
    'golden: Military tab empty state (Refs #4307)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('counselMilitaryPanelEmptyGolden');
      await pumpCounselMilitaryGolden(
        tester,
        boundaryKey: boundaryKey,
        child: counselMilitaryTabGoldenHost(
          recommendations: const [],
          callbacks: stubCallbacks,
        ),
      );

      expect(
        find.text('No pressing military advice this turn.'),
        findsOneWidget,
      );
      expect(find.byType(CtNinePatchButton), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/counsel_military_panel_empty.png'),
      );
    },
  );

  testWidgets(
    'golden: Military tab read-only hides Agree controls (Refs #4307)',
    (WidgetTester tester) async {
      const boundaryKey =
          ValueKey<String>('counselMilitaryPanelReadOnlyGolden');
      await pumpCounselMilitaryGolden(
        tester,
        boundaryKey: boundaryKey,
        child: counselMilitaryTabGoldenHost(
          recommendations: counselTestDefaultMilitaryRecommendations(),
          canEdit: false,
          callbacks: stubCallbacks,
        ),
      );

      expect(find.text('Agree'), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/counsel_military_panel_read_only.png'),
      );
    },
  );
}

void _noopTrain(MilitaryCounselRecommendation _) {}
void _noopInvade(MilitaryCounselRecommendation _) {}
