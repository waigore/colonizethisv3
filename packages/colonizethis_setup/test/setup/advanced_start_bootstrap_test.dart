import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';

Game _minimalGpGame({required Player player}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(provinces: []),
      newWorld: const RegionData(provinces: []),
    ),
    players: [player],
  );
}

void main() {
  group('applyAdvancedStartBootstrap', () {
    test('none leaves game unchanged', () {
      const player = Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
        treasury: 1000,
        workerPool: WorkerPool(peasants: 4),
      );
      final game = _minimalGpGame(player: player);
      final config = GameSetupConfig.defaultConfig;

      final out = applyAdvancedStartBootstrap(game: game, config: config);

      expect(out.advancedStartType, isNull);
      expect(out.worldState.turnState.turnNumber, 0);
      expect(out.players.single.treasury, 1000);
      expect(out.players.single.workerPool.peasants, 4);
    });

    test('turns50 applies turn, techs, treasury, and workforce on locked profile', () {
      const player = Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
        treasury: 1000,
        workerPool: WorkerPool(peasants: 4),
      );
      final game = _minimalGpGame(player: player);
      final config = GameSetupConfig(
        advancedStart: AdvancedStartType.turns50,
      );

      final out = applyAdvancedStartBootstrap(game: game, config: config);

      expect(out.advancedStartType, AdvancedStartType.turns50);
      expect(out.worldState.turnState.turnNumber, 50);
      expect(out.players.single.treasury, 20000);
      expect(out.players.single.workerPool.peasants, 16);
      expect(
        out.players.single.techUnlocked!.keys.where((k) => out.players.single.techUnlocked![k] == true),
        hasLength(23),
      );
    });

    test('turns100 applies apprentices and 45 techs on locked profile', () {
      const player = Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
      );
      final game = _minimalGpGame(player: player);
      final config = GameSetupConfig(
        advancedStart: AdvancedStartType.turns100,
      );

      final out = applyAdvancedStartBootstrap(game: game, config: config);

      expect(out.advancedStartType, AdvancedStartType.turns100);
      expect(out.worldState.turnState.turnNumber, 100);
      expect(out.players.single.treasury, 40000);
      expect(out.players.single.workerPool.peasants, 16);
      expect(out.players.single.workerPool.apprentices, 4);
      expect(
        out.players.single.techUnlocked!.keys.where((k) => out.players.single.techUnlocked![k] == true),
        hasLength(45),
      );
    });

    test('non-locked profile skips bootstrap', () {
      const player = Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
        treasury: 500,
      );
      final game = _minimalGpGame(player: player);
      final config = GameSetupConfig(
        numProvincesOldWorld: 24,
        numProvincesNewWorld: 12,
        advancedStart: AdvancedStartType.turns50,
      );

      final out = applyAdvancedStartBootstrap(game: game, config: config);

      expect(out.advancedStartType, isNull);
      expect(out.worldState.turnState.turnNumber, 0);
      expect(out.players.single.treasury, 500);
    });
  });
}
