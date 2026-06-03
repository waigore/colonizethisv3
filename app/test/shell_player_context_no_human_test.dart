import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Refs #3176 — fully-AI games (zero human players) must not break the
/// in-game shell helpers that historically assumed a human player existed.
Game _allAiGame() {
  return Game(
    id: 'g-all-ai',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      Player(id: 'gp1', displayName: 'Power 1', isHuman: false),
      Player(id: 'gp2', displayName: 'Power 2', isHuman: false),
    ],
    aiControlByGpId: const {'gp1': true, 'gp2': true},
  );
}

ShellPlayerContext _noHumanShell() {
  return const ShellPlayerContext(
    effectiveHumanPlayerId: null,
    viewingPlayerId: null,
    mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
    playerView: null,
    omniscientDetail: false,
    showPlayerChrome: true,
    canMutateViaUi: true,
    debugCommandTargetPlayerId: null,
    inObservePhase: false,
    observeBannerLabel: null,
    treasuryNotDefined: false,
    cargoNotDefined: false,
  );
}

void main() {
  suppressLogsForTests();

  group('shell helpers tolerate zero human players (Refs #3176)', () {
    test('mapPlayerIdFor falls back to first player and does not throw', () {
      final game = _allAiGame();
      final shell = _noHumanShell();
      expect(() => shell.mapPlayerIdFor(game), returnsNormally);
      expect(shell.mapPlayerIdFor(game), 'gp1');
    });

    test('resolveCivilianMarkerOwnerIds returns empty set for no-human, '
        'not-observing shell (no throw)', () {
      final game = _allAiGame();
      final shell = _noHumanShell();
      final ids = resolveCivilianMarkerOwnerIds(shell, game);
      expect(ids, isEmpty);
    });

    test('resolveShellPanelPlayerId falls back to first player when no human '
        'and no observe target', () {
      final game = _allAiGame();
      final shell = _noHumanShell();
      expect(resolveShellPanelPlayerId(shell, game), 'gp1');
    });
  });
}
