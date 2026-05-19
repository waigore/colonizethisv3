import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/observe_session_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Game _minimalGame({required List<Player> players, Map<String, bool>? aiControl}) {
  return Game(
    id: 'g1',
    players: players,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    aiControlByGpId: aiControl ?? const {},
  );
}

void main() {
  suppressLogsForTests();

  group('ObserveSessionNotifier', () {
    late ProviderContainer container;
    late ObserveSessionNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      container.read(observeSessionProvider);
      notifier = container.read(observeSessionProvider.notifier);
      notifier.reset();
    });

    tearDown(() {
      container.dispose();
    });

    test('applyObserveHandoff sets all GPs AI-controlled', () {
      final game = _minimalGame(
        players: [
          const Player(id: 'gp1', displayName: 'Human', isHuman: true),
          const Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );

      final next = notifier.applyObserveHandoffIfNeeded(game);

      expect(next.players.every((p) => !p.isHuman), isTrue);
      expect(next.aiControlByGpId, {'gp1': true, 'gp2': true});
      expect(notifier.state.priorHumanPlayerId, 'gp1');
    });

    test('prepareGameForPersistence restores baseline control flags', () {
      final game = _minimalGame(
        players: [
          const Player(id: 'gp1', displayName: 'Human', isHuman: true),
        ],
      );
      final handedOff = notifier.applyObserveHandoffIfNeeded(game);
      expect(handedOff.players.single.isHuman, isFalse);

      final persisted = notifier.prepareGameForPersistence(handedOff);
      expect(persisted.players.single.isHuman, isTrue);
    });

    test('shell context global observe uses not-defined panels', () {
      final game = _minimalGame(
        players: [
          const Player(id: 'gp1', displayName: 'Human', isHuman: true),
          const Player(id: 'gp2', displayName: 'France', isHuman: false),
        ],
      );
      final handedOff = notifier.applyObserveHandoffIfNeeded(game);
      container.read(currentGameProvider.notifier).setGame(handedOff);
      notifier.setModeGlobal();

      final shell = container.read(shellPlayerContextProvider);
      expect(shell.panelPlayerId, isNull);
      expect(shell.treasuryNotDefined, isTrue);
      expect(shell.showPlayerChrome, isFalse);
      expect(shell.mapVisibilityMode, CtMapVisibilityMode.full);
      expect(shell.omniscientDetail, isTrue);
      expect(shell.inObservePhase, isTrue);
      expect(shell.observeBannerLabel, 'Observing: global');
      expect(shell.debugCommandTargetPlayerId, 'gp1');
    });

    test('shell context player observe binds panel player', () {
      final game = _minimalGame(
        players: [
          const Player(id: 'gp1', displayName: 'Human', isHuman: true),
          const Player(id: 'gp2', displayName: 'France', isHuman: false),
        ],
      );
      final handedOff = notifier.applyObserveHandoffIfNeeded(game);
      container.read(currentGameProvider.notifier).setGame(handedOff);
      notifier.setModePlayer('gp2');

      final shell = container.read(shellPlayerContextProvider);
      expect(shell.panelPlayerId, 'gp2');
      expect(shell.showPlayerChrome, isTrue);
      expect(shell.canMutateViaUi, isFalse);
    });

    test('applyObserveOff restores prior human', () {
      final game = _minimalGame(
        players: [
          const Player(id: 'gp1', displayName: 'Human', isHuman: true),
          const Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final handedOff = notifier.applyObserveHandoffIfNeeded(game);
      final restored = notifier.applyObserveOff(handedOff);

      expect(restored.players.firstWhere((p) => p.id == 'gp1').isHuman, isTrue);
      expect(notifier.state.mode, ObserveMode.off);
    });
  });
}
