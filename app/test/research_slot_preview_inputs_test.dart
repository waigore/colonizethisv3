// Unit tests for seated-tech finish lookup (Refs #4511).
//
// SPEC: SPEC/ui/tech-tree-widget.md § Description dialog (Finish-time);
// SPEC/game/turn-time-mapping.md § Campaign calendar cap.

import 'package:colonizethis_app/features/game/widgets/technology/research_slot_preview_inputs.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';

Player _seated({
  required Player base,
  int progress = 40,
  int treasury = 2000,
  ResearchFundingLevel funding = ResearchFundingLevel.medium,
}) {
  return base.copyWith(
    treasury: treasury,
    researchSlots: 3,
    researchSlotAssignments: {
      0: ResearchSlotAssignment(techId: kTechIdSawMill, funding: funding),
    },
    researchProgressByTechId: {kTechIdSawMill: progress},
  );
}

Game _withPlayer(Game base, Player player, {int turn = 1}) {
  return base.copyWith(
    players: [player, ...base.players.skip(1)],
    worldState: base.worldState.copyWith(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turn),
    ),
  );
}

void main() {
  suppressLogsForTests();

  late Game baseGame;
  late Player basePlayer;

  setUpAll(() {
    baseGame = buildTechnologyPanelTestGame();
    basePlayer = baseGame.players.first;
  });

  test('positive: remaining RP covered this turn completes next turn', () {
    final player = _seated(base: basePlayer, progress: 1600);
    final game = _withPlayer(baseGame, player);
    final finish = researchFinishForSeatedTech(
      game: game,
      player: player,
      currentOrders: const Orders(),
      techId: kTechIdSawMill,
    );
    expect(finish, isNotNull);
    expect(finish!.estimate.completesNextTurn, isTrue);
    expect(finish.estimate.turnsRemaining, 1);
    expect(finish.calendarYear, isNotNull);
  });

  test('positive: remaining RP above this-turn RP uses ceil', () {
    final player = _seated(base: basePlayer, progress: 40);
    final game = _withPlayer(baseGame, player);
    final finish = researchFinishForSeatedTech(
      game: game,
      player: player,
      currentOrders: const Orders(),
      techId: kTechIdSawMill,
    );
    expect(finish, isNotNull);
    expect(finish!.estimate.completesNextTurn, isFalse);
    expect(finish.estimate.turnsRemaining, 6);
  });

  test('negative: unseated tech has no finish estimate', () {
    final player = _seated(base: basePlayer);
    final game = _withPlayer(baseGame, player);
    expect(
      researchFinishForSeatedTech(
        game: game,
        player: player,
        currentOrders: const Orders(),
        techId: kTechIdCropRotation,
      ),
      isNull,
    );
  });

  test('negative: None funding has no finish estimate', () {
    final player = _seated(
      base: basePlayer,
      funding: ResearchFundingLevel.none,
    );
    final game = _withPlayer(baseGame, player);
    expect(
      researchFinishForSeatedTech(
        game: game,
        player: player,
        currentOrders: const Orders(),
        techId: kTechIdSawMill,
      ),
      isNull,
    );
  });

  test('negative: year is suppressed when finish turn is after the cap', () {
    final player = _seated(base: basePlayer, progress: 40);
    final game = _withPlayer(baseGame, player, turn: 199);
    final finish = researchFinishForSeatedTech(
      game: game,
      player: player,
      currentOrders: const Orders(),
      techId: kTechIdSawMill,
    );
    expect(finish, isNotNull);
    expect(finish!.estimate.turnsRemaining, 6);
    expect(finish.calendarYear, isNull);
  });
}
