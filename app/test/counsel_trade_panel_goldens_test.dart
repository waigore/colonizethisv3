// Widget goldens for the Counsel Trade tab (GAME90001) visual acceptance
// criteria (Refs #4282). Pixel baselines live under `app/test/goldens/`.
//
// Golden mapping:
//  - AC actionable lines: default Trade tab with ≤3 recommendation cards
//  - AC stars / deep-link: highlight emphasizes focused card
//  - AC empty state: "No pressing market advice this turn."
//  - AC read-only: turn-resolution blocking hides Apply/Agree controls
//
// SPEC: SPEC/ui/counsel-panel.md § Trade tab.

import 'package:colonizethis_app/features/game/screens/counsel/counsel_trade_tab_body.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'counsel_trade_panel_test_support.dart';
import 'golden_capture_harness.dart';

void main() {
  suppressLogsForTests();

  final stubCallbacks = CounselTradeCallbacks(
    onApplyBook: _noop,
    onAgreeLine: _noopOrder,
  );

  Future<void> pumpCounselTradeGolden(
    WidgetTester tester, {
    required Key boundaryKey,
    required Widget child,
  }) async {
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: kCounselTradePanelGoldenViewport,
      includeLocalizations: true,
      center: false,
      child: child,
    );
  }

  testWidgets(
    'golden: Trade tab default with three recommendations (Refs #4282)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('counselTradePanelDefaultGolden');
      await pumpCounselTradeGolden(
        tester,
        boundaryKey: boundaryKey,
        child: counselTradeTabGoldenHost(
          recommendations: counselTestDefaultTradeRecommendations(),
          callbacks: stubCallbacks,
        ),
      );

      expect(find.text('Trade'), findsOneWidget);
      expect(find.text('Apply recommended market book'), findsOneWidget);
      expect(find.text('Agree'), findsNWidgets(3));
      expect(find.text('Offer Timber × 12'), findsOneWidget);
      expect(find.text('Bid Fabric × 6'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/counsel_trade_panel_default.png'),
      );
    },
  );

  testWidgets(
    'golden: Trade tab highlight emphasizes focused card (Refs #4282)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('counselTradePanelHighlightGolden');
      await pumpCounselTradeGolden(
        tester,
        boundaryKey: boundaryKey,
        child: counselTradeTabGoldenHost(
          recommendations: counselTestDefaultTradeRecommendations(),
          highlightRecommendationId: 'offer:timber',
          callbacks: stubCallbacks,
        ),
      );

      expect(find.text('Apply recommended market book'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/counsel_trade_panel_highlight.png'),
      );
    },
  );

  testWidgets(
    'golden: Trade tab empty state (Refs #4282)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('counselTradePanelEmptyGolden');
      await pumpCounselTradeGolden(
        tester,
        boundaryKey: boundaryKey,
        child: counselTradeTabGoldenHost(
          recommendations: const [],
          book: const [],
        ),
      );

      expect(
        find.text('No pressing market advice this turn.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/counsel_trade_panel_empty.png'),
      );
    },
  );

  testWidgets(
    'golden: Trade tab read-only hides Apply/Agree controls (Refs #4282)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('counselTradePanelReadOnlyGolden');
      await pumpCounselTradeGolden(
        tester,
        boundaryKey: boundaryKey,
        child: counselTradeTabGoldenHost(
          recommendations: counselTestDefaultTradeRecommendations(),
          canEdit: false,
        ),
      );

      expect(find.text('Apply recommended market book'), findsNothing);
      expect(find.text('Agree'), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/counsel_trade_panel_read_only.png'),
      );
    },
  );
}

void _noop() {}

void _noopOrder(TradeOrder _) {}
