// Unit and widget tests for GAME40001 spy-insight slot RP preview (Refs #4457).
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview;
// SPEC/program/research-resolution.md; SPEC/game/research-state.md § Spy RP boost.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show applySpyResearchBoostToPoints, researchPointsMedium;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/research_slot_preview.dart';
import 'package:colonizethis_app/features/game/widgets/technology/research_slot_spy_insight.dart';
import 'package:colonizethis_app/features/game/widgets/technology/research_slot_turn_preview_view.dart';
import 'package:colonizethis_app/features/game/widgets/technology/research_slot_turn_preview_view_breakdown.dart';

import 'panel_test_fixtures.dart';
import 'technology_panel_test_support.dart';

const String _kOw = 'oldWorld';
const String _kFranceProvince = 'oldWorld|fr1';
const String _kSpainProvince = 'oldWorld|es1';
const String _kTechId = kTechIdCropRotation;

Player _player({int treasury = 10000, Map<String, bool>? techUnlocked}) {
  return Player(
    id: 'gp1',
    displayName: 'England',
    isHuman: true,
    treasury: treasury,
    techUnlocked: techUnlocked,
  );
}

TechDefinition _tech() =>
    const TechDefinition(id: _kTechId, era: 1, category: 'civic', cost: 1800);

void main() {
  suppressLogsForTests();

  group('computeResearchSlotTurnPreview spy insight', () {
    test('positive: one rival applies +15% after industrial base', () {
      final preview = computeResearchSlotTurnPreview(
        player: _player(),
        tech: _tech(),
        committedProgress: 0,
        funding: ResearchFundingLevel.medium,
        qualifyingRivalGpCount: 1,
        qualifyingRivalDisplayNames: const ['France'],
      );

      final expected = applySpyResearchBoostToPoints(
        basePoints: researchPointsMedium,
        qualifyingRivalGpCount: 1,
      );
      expect(preview.anticipatedRpPerTurn, expected);
      expect(preview.spyInsightRpPerTurn, expected - researchPointsMedium);
      expect(preview.hasSpyInsight, isTrue);
      expect(preview.spyInsightRivalNames, ['France']);
    });

    test('positive: two rivals stack to ×1.30', () {
      final preview = computeResearchSlotTurnPreview(
        player: _player(),
        tech: _tech(),
        committedProgress: 0,
        funding: ResearchFundingLevel.medium,
        qualifyingRivalGpCount: 2,
        qualifyingRivalDisplayNames: const ['France', 'Spain'],
      );

      final expected = applySpyResearchBoostToPoints(
        basePoints: researchPointsMedium,
        qualifyingRivalGpCount: 2,
      );
      expect(preview.anticipatedRpPerTurn, expected);
      expect(expected, researchPointsMedium * 13 ~/ 10);
      expect(preview.spyInsightRivalNames, ['France', 'Spain']);
    });

    test('positive: spy insight applies after the industrial bonus', () {
      final preview = computeResearchSlotTurnPreview(
        player: _player(
          techUnlocked: const {kTechIdIndustrialFundingOfResearch: true},
        ),
        tech: const TechDefinition(
          id: 'military_t',
          era: 1,
          category: 'military',
          cost: 1800,
        ),
        committedProgress: 0,
        funding: ResearchFundingLevel.medium,
        qualifyingRivalGpCount: 1,
        qualifyingRivalDisplayNames: const ['France'],
      );
      final industrialAdjusted = (researchPointsMedium * 1.2).floor();
      expect(
        preview.anticipatedRpPerTurn,
        applySpyResearchBoostToPoints(
          basePoints: industrialAdjusted,
          qualifyingRivalGpCount: 1,
        ),
      );
    });

    test('negative: funding None keeps 0 RP and no spy row fields', () {
      final preview = computeResearchSlotTurnPreview(
        player: _player(),
        tech: _tech(),
        committedProgress: 0,
        funding: ResearchFundingLevel.none,
        qualifyingRivalGpCount: 1,
        qualifyingRivalDisplayNames: const ['France'],
      );

      expect(preview.anticipatedRpPerTurn, 0);
      expect(preview.hasSpyInsight, isFalse);
      expect(preview.spyInsightRivalNames, isEmpty);
    });

    test('negative: debt-blocked slot keeps 0 RP and no spy row fields', () {
      final preview = computeResearchSlotTurnPreview(
        player: _player(treasury: 0),
        tech: _tech(),
        committedProgress: 0,
        funding: ResearchFundingLevel.medium,
        qualifyingRivalGpCount: 1,
        qualifyingRivalDisplayNames: const ['France'],
      );

      expect(preview.debtBlocked, isTrue);
      expect(preview.anticipatedRpPerTurn, 0);
      expect(preview.hasSpyInsight, isFalse);
    });

    test('negative: sequential-blocked later slot omits spy insight', () {
      final sequential = computeResearchSlotsTurnPreview(
        player: _player(treasury: 200),
        occupiedSlots: [
          ResearchSlotPreviewInput(
            slotIndex: 0,
            tech: _tech(),
            committedProgress: 0,
            funding: ResearchFundingLevel.medium,
            qualifyingRivalGpCount: 1,
            qualifyingRivalDisplayNames: const ['France'],
          ),
          ResearchSlotPreviewInput(
            slotIndex: 1,
            tech: _tech(),
            committedProgress: 0,
            funding: ResearchFundingLevel.medium,
            qualifyingRivalGpCount: 1,
            qualifyingRivalDisplayNames: const ['France'],
          ),
        ],
      );

      expect(sequential.bySlotIndex[0]!.hasSpyInsight, isTrue);
      expect(sequential.bySlotIndex[1]!.sequentialBlocked, isTrue);
      expect(sequential.bySlotIndex[1]!.anticipatedRpPerTurn, 0);
      expect(sequential.bySlotIndex[1]!.hasSpyInsight, isFalse);
      expect(
        sequential.totalRp,
        sequential.bySlotIndex[0]!.anticipatedRpPerTurn,
      );
    });
  });

  group('spyInsightForResearchPreview', () {
    test('positive: names the rival court that unlocked the tech', () {
      final game = _spyInsightGame(rivalCount: 1);
      final insight = spyInsightForResearchPreview(
        game: game,
        playerId: 'gp1',
        techId: _kTechId,
      );
      expect(insight.count, 1);
      expect(insight.names, ['France']);
    });

    test('positive: two rivals both named', () {
      final game = _spyInsightGame(rivalCount: 2);
      final insight = spyInsightForResearchPreview(
        game: game,
        playerId: 'gp1',
        techId: _kTechId,
      );
      expect(insight.count, 2);
      expect(insight.names, ['France', 'Spain']);
    });

    test('negative: spy in a court that has not unlocked the tech', () {
      final game = _spyInsightGame(rivalCount: 1, rivalUnlocked: false);
      final insight = spyInsightForResearchPreview(
        game: game,
        playerId: 'gp1',
        techId: _kTechId,
      );
      expect(insight.count, 0);
      expect(insight.names, isEmpty);
    });
  });

  group('TechnologyPanel spy insight', () {
    testWidgets('positive: funded slot +N RP includes one-rival spy insight', (
      WidgetTester tester,
    ) async {
      final game = _spyInsightGame(rivalCount: 1);
      final player = game.players.first.copyWith(treasury: 8000);
      final expected = applySpyResearchBoostToPoints(
        basePoints: researchPointsMedium,
        qualifyingRivalGpCount: 1,
      );
      await pumpTechnologyPanel(
        tester,
        game: game.copyWith(players: [player, ...game.players.skip(1)]),
        player: player,
        currentOrders: Orders(
          researchOrdersByPlayerId: {
            player.id: [
              ResearchOrder(
                slotIndex: 0,
                techId: _kTechId,
                funding: ResearchFundingLevel.medium,
              ),
            ],
          },
        ),
        onOrdersChanged: (_) {},
      );

      expect(find.text('+$expected RP'), findsWidgets);
      await tester.tap(find.byKey(ResearchSlotTurnPreviewView.rpDeltaKey(0)));
      await tester.pumpAndSettle();
      expect(find.byType(ResearchFundingBreakdownDialog), findsOneWidget);
      expect(
        find.text('Spy insight — France already knows this (+15%)'),
        findsOneWidget,
      );
    });

    testWidgets('positive: two-rival stack names both courts at +30%', (
      WidgetTester tester,
    ) async {
      final game = _spyInsightGame(rivalCount: 2);
      final player = game.players.first.copyWith(treasury: 8000);
      await pumpTechnologyPanel(
        tester,
        game: game.copyWith(players: [player, ...game.players.skip(1)]),
        player: player,
        currentOrders: Orders(
          researchOrdersByPlayerId: {
            player.id: [
              ResearchOrder(
                slotIndex: 0,
                techId: _kTechId,
                funding: ResearchFundingLevel.medium,
              ),
            ],
          },
        ),
        onOrdersChanged: (_) {},
      );

      await tester.tap(find.byKey(ResearchSlotTurnPreviewView.rpDeltaKey(0)));
      await tester.pumpAndSettle();
      expect(
        find.text('Spy insight — France and Spain already know this (+30%)'),
        findsOneWidget,
      );
    });

    testWidgets('negative: funding None does not show a spy insight row', (
      WidgetTester tester,
    ) async {
      final game = _spyInsightGame(rivalCount: 1);
      final player = game.players.first.copyWith(treasury: 8000);
      await pumpTechnologyPanel(
        tester,
        game: game.copyWith(players: [player, ...game.players.skip(1)]),
        player: player,
        currentOrders: Orders(
          researchOrdersByPlayerId: {
            player.id: [
              ResearchOrder(
                slotIndex: 0,
                techId: _kTechId,
                funding: ResearchFundingLevel.none,
              ),
            ],
          },
        ),
        onOrdersChanged: (_) {},
      );

      expect(
        find.byKey(ResearchSlotTurnPreviewView.rpDeltaKey(0)),
        findsNothing,
      );
      expect(find.textContaining('Spy insight'), findsNothing);
    });
  });
}

Game _spyInsightGame({required int rivalCount, bool rivalUnlocked = true}) {
  const human = Player(id: 'gp1', displayName: 'England', isHuman: true);
  final unlocked = rivalUnlocked ? const {_kTechId: true} : null;
  final france = Player(
    id: 'gp2',
    displayName: 'France',
    isHuman: false,
    techUnlocked: unlocked,
  );
  final spain = Player(
    id: 'gp3',
    displayName: 'Spain',
    isHuman: false,
    techUnlocked: unlocked,
  );
  return buildPanelTestGame(
    id: 'spy-insight-preview',
    players: rivalCount >= 2 ? [human, france, spain] : [human, france],
    oldWorldProvinces: [
      const Province(id: _kFranceProvince, regionId: _kOw, ownerId: 'gp2'),
      if (rivalCount >= 2)
        const Province(id: _kSpainProvince, regionId: _kOw, ownerId: 'gp3'),
    ],
    oldWorldUnits: [
      Unit(
        id: 'spy_fr',
        type: kUnitTypeSpy,
        ownerId: human.id,
        locationProvinceId: _kFranceProvince,
        tileKey: '$_kFranceProvince|0|0',
      ),
      if (rivalCount >= 2)
        Unit(
          id: 'spy_es',
          type: kUnitTypeSpy,
          ownerId: human.id,
          locationProvinceId: _kSpainProvince,
          tileKey: '$_kSpainProvince|0|0',
        ),
    ],
  );
}
