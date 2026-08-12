// Visual goldens for GAME40001 sequential multi-slot research funding (Refs #4335):
// the empire-wide "Research this turn" header plus per-slot sequential walk
// honesty when treasury cannot fund every seat, and the fully-funded case
// where header totals match the sum of per-slot spends.
//
// These close the AC-1 / AC-2 visual golden gap flagged on issue #4335's
// verification — widget/unit tests already pin the logic; this file adds
// `matchesGoldenFile` baselines for the full TechnologyPanel Slots body.
//
// Rendered against `AppThemes.editorialMonocle` at device pixel ratio 1.0 via
// `pumpTechnologyPanelGolden`, matching the committed harness pattern
// (`technology_slots_panel_parity_goldens_test.dart`).
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview + § Widgetbook.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/research_turn_funding_header.dart';
import 'package:colonizethis_app/features/game/widgets/technology/research_slot_turn_preview_view.dart';

import 'panel_test_fixtures.dart';
import 'technology_panel_test_support.dart';

const List<String> _kAmpleTreasuryTechIds = <String>[
  kTechIdCropRotation,
  kTechIdSawMill,
  kTechIdLandEnclosure,
];

const List<int> _kAmpleTreasuryCommittedRp = <int>[600, 300, 0];

const List<ResearchFundingLevel> _kAmpleTreasuryFunding =
    <ResearchFundingLevel>[
  ResearchFundingLevel.medium,
  ResearchFundingLevel.high,
  ResearchFundingLevel.low,
];

const List<String> _kSequentialBlockedTechIds = <String>[
  kTechIdCropRotation,
  kTechIdSawMill,
];

({Game game, Player player, Orders orders}) _sequentialBlockedFixture({
  required Game baseGame,
  required Player basePlayer,
}) {
  final player = basePlayer.copyWith(
    treasury: 200,
    researchSlots: 3,
  );
  final game = baseGame.copyWith(
    players: [player, ...baseGame.players.skip(1)],
  );
  final orders = Orders(
    researchOrdersByPlayerId: <String, List<ResearchOrder>>{
      player.id: <ResearchOrder>[
        for (var i = 0; i < _kSequentialBlockedTechIds.length; i++)
          ResearchOrder(
            slotIndex: i,
            techId: _kSequentialBlockedTechIds[i],
            funding: ResearchFundingLevel.medium,
          ),
      ],
    },
  );
  return (game: game, player: player, orders: orders);
}

({Game game, Player player, Orders orders}) _ampleTreasuryFundedFixture({
  required Game baseGame,
  required Player basePlayer,
}) {
  final progress = <String, int>{
    for (var i = 0; i < _kAmpleTreasuryTechIds.length; i++)
      _kAmpleTreasuryTechIds[i]: _kAmpleTreasuryCommittedRp[i],
  };
  final player = basePlayer.copyWith(
    treasury: 8000,
    researchSlots: 3,
    researchProgressByTechId: progress,
  );
  final game = baseGame.copyWith(
    players: [player, ...baseGame.players.skip(1)],
  );
  final orders = Orders(
    researchOrdersByPlayerId: <String, List<ResearchOrder>>{
      player.id: <ResearchOrder>[
        for (var i = 0; i < _kAmpleTreasuryTechIds.length; i++)
          ResearchOrder(
            slotIndex: i,
            techId: _kAmpleTreasuryTechIds[i],
            funding: _kAmpleTreasuryFunding[i],
          ),
      ],
    },
  );
  return (game: game, player: player, orders: orders);
}

void main() {
  suppressLogsForTests();

  late Game baseGame;
  late Player basePlayer;

  setUpAll(() {
    baseGame = buildTechnologyPanelTestGame();
    basePlayer = baseGame.players.first;
  });

  testWidgets(
    'golden: sequential-blocked slots show partial header at desktop (Refs #4335 AC1)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'technologySequentialBlockedPanelGolden',
      );
      const viewport = Size(900, 760);
      final fixture = _sequentialBlockedFixture(
        baseGame: baseGame,
        basePlayer: basePlayer,
      );

      await pumpTechnologyPanelGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: viewport,
        game: fixture.game,
        player: fixture.player,
        currentOrders: fixture.orders,
      );

      expect(find.byKey(ResearchTurnFundingHeader.summaryKey), findsOneWidget);
      expect(
        find.text('Not enough gold left after earlier slots'),
        findsOneWidget,
      );
      expect(
        find.byKey(ResearchSlotTurnPreviewView.anticipatedSegmentKey(0)),
        findsOneWidget,
      );
      expect(
        find.byKey(ResearchSlotTurnPreviewView.anticipatedSegmentKey(1)),
        findsNothing,
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/technology_slots_sequential_blocked_desktop.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: ample-treasury funded slots show header totals at desktop (Refs #4335 AC2)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'technologyAmpleTreasuryFundedPanelGolden',
      );
      const viewport = Size(900, 760);
      final fixture = _ampleTreasuryFundedFixture(
        baseGame: baseGame,
        basePlayer: basePlayer,
      );

      await pumpTechnologyPanelGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: viewport,
        game: fixture.game,
        player: fixture.player,
        currentOrders: fixture.orders,
      );

      expect(find.byKey(ResearchTurnFundingHeader.summaryKey), findsOneWidget);
      expect(find.textContaining('Research this turn'), findsOneWidget);
      for (var slot = 0; slot < _kAmpleTreasuryTechIds.length; slot++) {
        expect(
          find.byKey(ResearchSlotTurnPreviewView.anticipatedSegmentKey(slot)),
          findsOneWidget,
        );
      }

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/technology_slots_ample_treasury_funded_desktop.png',
        ),
      );
    },
  );
}
