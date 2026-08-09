// Widget goldens for the Counsel Industry tab (GAME90001) visual acceptance
// criteria (Refs #4191). Pixel baselines live under `app/test/goldens/`.
//
// Golden mapping:
//  - AC1 default Industry tab with ≤3 recommendation cards
//  - AC2 deep-link highlight with detail copy visible
//  - AC7 empty-state copy
//  - AC8 read-only (turn-resolution blocking) without Agree controls
//
// SPEC: SPEC/ui/counsel-panel.md § Acceptance criteria.

import 'package:colonizethis_app/features/game/screens/counsel/counsel_industry_tab_body.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'counsel_panel_test_support.dart';
import 'golden_capture_harness.dart';

void main() {
  suppressLogsForTests();

  final stubCallbacks = CounselIndustryCallbacks(
    onApplyProduceAllocation: _noop,
    onAgreeTrain: _noopTier,
    onOpenDevelopment: _noop,
  );

  Future<void> pumpCounselGolden(
    WidgetTester tester, {
    required Key boundaryKey,
    required Widget child,
  }) async {
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: kCounselPanelGoldenViewport,
      includeLocalizations: true,
      center: false,
      child: child,
    );
  }

  testWidgets(
    'golden: Industry tab default with three recommendations (Refs #4191)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('counselPanelDefaultGolden');
      await pumpCounselGolden(
        tester,
        boundaryKey: boundaryKey,
        child: counselIndustryTabGoldenHost(
          recommendations: counselTestDefaultRecommendations(),
          callbacks: stubCallbacks,
        ),
      );

      expect(find.text('Industry'), findsOneWidget);
      expect(find.text('Apply recommended industry allocation'), findsOneWidget);
      expect(find.text('Agree'), findsOneWidget);
      expect(find.text('Open Development'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/counsel_panel_default.png'),
      );
    },
  );

  testWidgets(
    'golden: Industry tab highlight emphasizes focused card (Refs #4191)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('counselPanelHighlightGolden');
      await pumpCounselGolden(
        tester,
        boundaryKey: boundaryKey,
        child: counselIndustryTabGoldenHost(
          recommendations: counselTestDefaultRecommendations(),
          highlightRecommendationId: 'produce:lumber_from_timber',
          callbacks: stubCallbacks,
        ),
      );

      expect(find.text('Apply recommended industry allocation'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/counsel_panel_highlight.png'),
      );
    },
  );

  testWidgets(
    'golden: Industry tab empty state (Refs #4191)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('counselPanelEmptyGolden');
      await pumpCounselGolden(
        tester,
        boundaryKey: boundaryKey,
        child: counselIndustryTabGoldenHost(recommendations: const []),
      );

      expect(
        find.text('No pressing industry advice this turn.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/counsel_panel_empty.png'),
      );
    },
  );

  testWidgets(
    'golden: Industry tab read-only hides Agree controls (Refs #4191)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('counselPanelReadOnlyGolden');
      await pumpCounselGolden(
        tester,
        boundaryKey: boundaryKey,
        child: counselIndustryTabGoldenHost(
          recommendations: counselTestDefaultRecommendations(),
          canEdit: false,
        ),
      );

      expect(find.text('Apply recommended industry allocation'), findsNothing);
      expect(find.text('Agree'), findsNothing);
      expect(find.text('Open Development'), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/counsel_panel_read_only.png'),
      );
    },
  );
}

void _noop() {}

void _noopTier(WorkerTier _) {}
