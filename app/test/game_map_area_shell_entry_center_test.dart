// Shell-entry capital auto-center + home-to-capital observe gating.
// SPEC/ui/empire-overview.md § Initial map viewport (shell entry),
// § Home-to-capital button. SPEC/ui/observe-mode.md. Refs #3616.

import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group(
    'GameMapAreaStateLogicShell.resolveShellEntryAutoCenter (Refs #3616)',
    () {
      Game gameWith({CapitalTile? gp1Capital, CapitalTile? gp2Capital}) {
        return Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(provinces: [], units: []),
            newWorld: const RegionData(provinces: [], units: []),
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'Human',
              isHuman: true,
              capitalTile: gp1Capital,
            ),
            Player(
              id: 'gp2',
              displayName: 'Rival',
              isHuman: false,
              capitalTile: gp2Capital,
            ),
          ],
          minorNations: const [],
          tribes: const [],
        );
      }

      test('oldWorld capital resolves region index 0 and capital tile key', () {
        const capital = CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'p1',
          x: 2,
          y: 3,
        );
        final target = GameMapAreaStateLogicShell.resolveShellEntryAutoCenter(
          game: gameWith(gp1Capital: capital),
          currentPlayerId: 'gp1',
        );
        expect(target, isNotNull);
        expect(target!.regionIndex, 0);
        expect(target.tileKey, capital.toTileKey());
      });

      test('newWorld capital resolves region index 1', () {
        const capital = CapitalTile(
          regionId: 'newWorld',
          provinceId: 'p9',
          x: 5,
          y: 6,
        );
        final target = GameMapAreaStateLogicShell.resolveShellEntryAutoCenter(
          game: gameWith(gp1Capital: capital),
          currentPlayerId: 'gp1',
        );
        expect(target, isNotNull);
        expect(target!.regionIndex, 1);
        expect(target.tileKey, capital.toTileKey());
      });

      test('null currentPlayerId (global observe) returns null', () {
        const capital = CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'p1',
          x: 0,
          y: 0,
        );
        final target = GameMapAreaStateLogicShell.resolveShellEntryAutoCenter(
          game: gameWith(gp1Capital: capital),
          currentPlayerId: null,
        );
        expect(target, isNull);
      });

      test('player without capitalTile returns null', () {
        final target = GameMapAreaStateLogicShell.resolveShellEntryAutoCenter(
          game: gameWith(),
          currentPlayerId: 'gp1',
        );
        expect(target, isNull);
      });

      test('unknown player id returns null', () {
        const capital = CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'p1',
          x: 1,
          y: 1,
        );
        final target = GameMapAreaStateLogicShell.resolveShellEntryAutoCenter(
          game: gameWith(gp1Capital: capital),
          currentPlayerId: 'nope',
        );
        expect(target, isNull);
      });

      test('player observe targets the observed GP capital', () {
        const gp2Capital = CapitalTile(
          regionId: 'newWorld',
          provinceId: 'p2',
          x: 4,
          y: 4,
        );
        final target = GameMapAreaStateLogicShell.resolveShellEntryAutoCenter(
          game: gameWith(
            gp1Capital: const CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'p1',
              x: 0,
              y: 0,
            ),
            gp2Capital: gp2Capital,
          ),
          currentPlayerId: 'gp2',
        );
        expect(target, isNotNull);
        expect(target!.tileKey, gp2Capital.toTileKey());
        expect(target.regionIndex, 1);
      });

      test('uses the current (reassigned) capital tile, not turn-0 value', () {
        const reassigned = CapitalTile(
          regionId: 'newWorld',
          provinceId: 'p77',
          x: 7,
          y: 8,
        );
        final target = GameMapAreaStateLogicShell.resolveShellEntryAutoCenter(
          game: gameWith(gp1Capital: reassigned),
          currentPlayerId: 'gp1',
        );
        expect(target, isNotNull);
        expect(target!.tileKey, reassigned.toTileKey());
      });
    },
  );
}
