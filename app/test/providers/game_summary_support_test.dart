import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_app/providers/game_summary_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Probe inputs exercising [computeGameSummary] short-circuit paths. The
/// map-present, no-map, and error compute paths are covered end-to-end by
/// `home_fleet_cargo_provider_test.dart`; these tests pin the preamble
/// (`whenNoGame` / `whenNotDefined`) that runs before any [GameService] access
/// (#3279 target state #8).
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

String _probe({
  required Game? game,
  required ShellPlayerContext shell,
}) {
  return computeGameSummary<String>(
    game: game,
    shell: shell,
    orders: const Orders(),
    gameService: _gameService,
    whenNoGame: 'no-game',
    notDefined: (shell) => shell.treasuryNotDefined,
    whenNotDefined: () => 'not-defined',
    log: packageLogger('test_game_summary'),
    compute: (context) => context.hasMapData
        ? 'map:${context.playerId}'
        : 'no-map:${context.playerId}',
    onError: (game, playerId) => 'error:$playerId',
  );
}

late final GameService _gameService;

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_summary_support');
    final box = await Hive.openBox<dynamic>('games_game_summary_support');
    _gameService = GameService(box, GameSaveAdapter());
  });

  test('returns whenNoGame and never reads the shell when no game is set', () {
    expect(_probe(game: null, shell: _shell(notDefined: false)), 'no-game');
  });

  test(
    'returns whenNotDefined when the shell marks the summary not-defined',
    () {
      expect(
        _probe(game: _game(), shell: _shell(notDefined: true)),
        'not-defined',
      );
    },
  );
}
