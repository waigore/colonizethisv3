// Refs #3279 — verifies the shared GamePanelMixin / GamePanelConfig contract
// is adopted by the fully-shaped game-bearing panels.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/game_panel_contract.dart';
import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';

Game _minimalGame() {
  return const Game(
    id: 'g-panel-contract',
    worldState: WorldState(
      turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: []),
      newWorld: RegionData(provinces: []),
    ),
    players: [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
}

void main() {
  suppressLogsForTests();

  group('GamePanelMixin contract (Refs #3279)', () {
    final game = _minimalGame();
    final bus = AppEventBus.create();
    const humanPlayerId = 'p1';

    test('MilitaryUnitsPanel exposes the shared contract', () {
      final panel = MilitaryUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: bus,
        topology: const MapTopology(),
        draftOrders: const Orders(),
        readOnly: true,
      );
      expect(panel, isA<GamePanelMixin>());
      final config = panel.gamePanelConfig;
      expect(config.game, same(game));
      expect(config.humanPlayerId, humanPlayerId);
      expect(config.bus, same(bus));
      expect(config.readOnly, isTrue);
    });

    test('NavalUnitsPanel exposes the shared contract', () {
      final panel = NavalUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: bus,
        topology: const MapTopology(),
      );
      expect(panel, isA<GamePanelMixin>());
      final config = panel.gamePanelConfig;
      expect(config.game, same(game));
      expect(config.humanPlayerId, humanPlayerId);
      expect(config.bus, same(bus));
      expect(config.readOnly, isFalse);
    });

    test('DiplomacyPanel exposes the shared contract', () {
      final panel = DiplomacyPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        topology: const MapTopology(),
        currentOrders: const Orders(),
        bus: bus,
      );
      expect(panel, isA<GamePanelMixin>());
      final config = panel.gamePanelConfig;
      expect(config.game, same(game));
      expect(config.humanPlayerId, humanPlayerId);
      expect(config.bus, same(bus));
      expect(config.readOnly, isFalse);
    });

    test('CivilianUnitsPanel exposes the shared contract', () {
      final panel = CivilianUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: bus,
        readOnly: true,
      );
      expect(panel, isA<GamePanelMixin>());
      final config = panel.gamePanelConfig;
      expect(config.game, same(game));
      expect(config.humanPlayerId, humanPlayerId);
      expect(config.bus, same(bus));
      expect(config.readOnly, isTrue);
    });

    test('gamePanelConfig reflects live field values', () {
      final panel = MilitaryUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: bus,
        topology: const MapTopology(),
        draftOrders: const Orders(),
      );
      // readOnly defaults to false when not supplied.
      expect(panel.gamePanelConfig.readOnly, isFalse);
    });
  });
}
