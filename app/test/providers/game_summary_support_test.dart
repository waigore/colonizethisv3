import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_app/providers/game_summary_support.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Probe provider exercising [watchGameSummary] in isolation. The map-present,
/// no-map, and error compute paths are covered end-to-end by
/// `home_fleet_cargo_provider_test.dart`; this probe pins the short-circuit
/// preamble (`whenNoGame` / `whenNotDefined`) that runs before any
/// `gameServiceProvider` access (#3279 target state #8).
final _probeProvider = Provider<String>((ref) {
  return watchGameSummary<String>(
    ref,
    whenNoGame: 'no-game',
    notDefined: (shell) => shell.treasuryNotDefined,
    whenNotDefined: () => 'not-defined',
    log: packageLogger('test_game_summary'),
    compute: (context) => context.hasMapData
        ? 'map:${context.playerId}'
        : 'no-map:${context.playerId}',
    onError: (game, playerId) => 'error:$playerId',
  );
});

Game _game() => Game(
  id: 'g-summary',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  ),
  players: [
    Player(id: 'gp1', displayName: 'Power 1', isHuman: true),
    Player(id: 'gp2', displayName: 'Power 2', isHuman: false),
  ],
);

ShellPlayerContext _shell({required bool notDefined}) => ShellPlayerContext(
  effectiveHumanPlayerId: 'gp1',
  viewingPlayerId: 'gp1',
  mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
  playerView: null,
  omniscientDetail: false,
  showPlayerChrome: true,
  canMutateViaUi: true,
  debugCommandTargetPlayerId: 'gp1',
  inObservePhase: false,
  observeBannerLabel: null,
  treasuryNotDefined: notDefined,
  cargoNotDefined: notDefined,
);

void main() {
  suppressLogsForTests();

  test('returns whenNoGame and never reads the shell when no game is set', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(_probeProvider), 'no-game');
  });

  test(
    'returns whenNotDefined when the shell marks the summary not-defined',
    () {
      final container = ProviderContainer(
        overrides: [
          shellPlayerContextProvider.overrideWith(
            (ref) => _shell(notDefined: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(currentGameProvider.notifier).setGame(_game());

      expect(container.read(_probeProvider), 'not-defined');
    },
  );
}
