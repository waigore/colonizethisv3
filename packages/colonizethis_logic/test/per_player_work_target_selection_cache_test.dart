import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  suppressLogsForTests();

  group('PerPlayerWorkTargetSelectionCache', () {
    WorkTargetSelectionSnapshot snapshotForPlayer(String playerId) {
      return WorkTargetSelectionSnapshot(
        game: Game(
          id: 'g_$playerId',
          worldState: const WorldState(
            turnState: TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: RegionData(provinces: [], units: []),
            newWorld: RegionData(provinces: [], units: []),
          ),
          players: [
            Player(
              id: playerId,
              displayName: playerId,
              isHuman: true,
            ),
          ],
        ),
        playerId: playerId,
        playerView: PlayerView(
          playerId: playerId,
          player: Player(
            id: playerId,
            displayName: playerId,
            isHuman: true,
          ),
          ownUnitsById: const {},
          provincesById: const {},
          visibilityByTile: const {'oldWorld|p1|0|0': VisibilityLevel.fogged},
          prospectedTiles: const {},
          diplomacyByOtherId: const {},
        ),
        topology: const MapTopology(nodes: [], edges: []),
        currentOrders: const Orders(),
        tileMapByRegion: null,
      );
    }

    test('sorted returns deterministic ordering', () {
      final cache = PerPlayerWorkTargetSelectionCache(
        strategies: {
          kWorkTargetExplore: (_) => {'oldWorld|p1|2|0', 'oldWorld|p1|0|0', 'oldWorld|p1|1|0'},
        },
      );

      cache.refresh(snapshotForPlayer('gp1'));

      expect(
        cache.sorted('gp1', kWorkTargetExplore),
        ['oldWorld|p1|0|0', 'oldWorld|p1|1|0', 'oldWorld|p1|2|0'],
      );
    });

    test('contains returns false for missing membership', () {
      final cache = PerPlayerWorkTargetSelectionCache(
        strategies: {
          kWorkTargetBuildImprovement: (_) => {'oldWorld|p2|1|1'},
        },
      );

      cache.refresh(snapshotForPlayer('gp1'));

      expect(
        cache.contains('gp1', kWorkTargetBuildImprovement, 'oldWorld|p2|2|2'),
        isFalse,
      );
    });

    test('refresh replaces target membership on turn-boundary style update', () {
      var turnNumber = 1;
      final cache = PerPlayerWorkTargetSelectionCache(
        strategies: {
          kWorkTargetExplore: (_) => turnNumber == 1 ? {'oldWorld|p1|0|0'} : {'oldWorld|p1|1|0'},
        },
      );

      final snapshot = snapshotForPlayer('gp1');
      cache.refresh(snapshot);
      expect(cache.get('gp1', kWorkTargetExplore), {'oldWorld|p1|0|0'});

      turnNumber = 2;
      cache.refresh(snapshot);
      expect(cache.get('gp1', kWorkTargetExplore), {'oldWorld|p1|1|0'});
      expect(cache.contains('gp1', kWorkTargetExplore, 'oldWorld|p1|0|0'), isFalse);
    });

    test('refresh keeps cache isolated per player', () {
      final cache = PerPlayerWorkTargetSelectionCache(
        strategies: {
          kWorkTargetExplore: (snapshot) => {'${snapshot.playerId}|tile'},
        },
      );

      cache.refresh(snapshotForPlayer('gp1'));
      cache.refresh(snapshotForPlayer('gp2'));

      expect(cache.get('gp1', kWorkTargetExplore), {'gp1|tile'});
      expect(cache.get('gp2', kWorkTargetExplore), {'gp2|tile'});
    });

    test('refresh stores and reads prospect membership', () {
      final cache = PerPlayerWorkTargetSelectionCache(
        strategies: {
          kWorkTargetProspect: (_) => {'oldWorld|p3|4|2', 'oldWorld|p3|2|1'},
        },
      );

      cache.refresh(snapshotForPlayer('gp1'));

      expect(
        cache.get('gp1', kWorkTargetProspect),
        {'oldWorld|p3|4|2', 'oldWorld|p3|2|1'},
      );
      expect(
        cache.sorted('gp1', kWorkTargetProspect),
        ['oldWorld|p3|2|1', 'oldWorld|p3|4|2'],
      );
    });

    test(
      'refresh injects one shared incremental validator for all strategies',
      () {
        Object? exploreValidator;
        Object? prospectValidator;
        final cache = PerPlayerWorkTargetSelectionCache(
          strategies: {
            kWorkTargetExplore: (snapshot) {
              exploreValidator = snapshot.sharedCandidateValidator;
              return const {'t1'};
            },
            kWorkTargetProspect: (snapshot) {
              prospectValidator = snapshot.sharedCandidateValidator;
              return const {'t2'};
            },
          },
        );

        cache.refresh(snapshotForPlayer('gp1'));

        expect(exploreValidator, isNotNull);
        expect(prospectValidator, same(exploreValidator));
      },
    );

    test(
      'refresh reuses caller-supplied playerOwnedProvinceIds when set (Refs #2394)',
      () {
        final base = snapshotForPlayer('gp1');
        final ownedIds = <String>{
          for (final e in base.playerView.provincesById.entries)
            if (e.value.ownerId == base.playerId) e.key,
        };
        Object? seenOwned;
        final cache = PerPlayerWorkTargetSelectionCache(
          strategies: {
            kWorkTargetExplore: (snapshot) {
              seenOwned = snapshot.playerOwnedProvinceIds;
              return const {'t1'};
            },
          },
        );
        cache.refresh(
          WorkTargetSelectionSnapshot(
            game: base.game,
            playerId: base.playerId,
            playerView: base.playerView,
            topology: base.topology,
            currentOrders: base.currentOrders,
            tileMapByRegion: base.tileMapByRegion,
            playerOwnedProvinceIds: ownedIds,
          ),
        );
        expect(seenOwned, same(ownedIds));
      },
    );

    test(
      'refresh built validator reuses snapshot playerView (Refs #2394)',
      () {
        final base = snapshotForPlayer('gp1');
        Object? validatorView;
        final cache = PerPlayerWorkTargetSelectionCache(
          strategies: {
            kWorkTargetExplore: (snapshot) {
              validatorView = snapshot.sharedCandidateValidator?.view;
              return const {'t1'};
            },
          },
        );
        cache.refresh(base);
        expect(validatorView, same(base.playerView));
      },
    );

    test(
      'refresh reuses caller-supplied sharedCandidateValidator when set (Refs #2394)',
      () {
        final base = snapshotForPlayer('gp1');
        final external = IncrementalCandidateValidator.forPlayer(
          game: base.game,
          topology: base.topology,
          playerId: base.playerId,
          basePrefix: base.currentOrders,
          tileMapByRegion: base.tileMapByRegion,
          view: base.playerView,
        );
        Object? seen;
        final cache = PerPlayerWorkTargetSelectionCache(
          strategies: {
            kWorkTargetExplore: (snapshot) {
              seen = snapshot.sharedCandidateValidator;
              return const {'t1'};
            },
          },
        );
        cache.refresh(
          WorkTargetSelectionSnapshot(
            game: base.game,
            playerId: base.playerId,
            playerView: base.playerView,
            topology: base.topology,
            currentOrders: base.currentOrders,
            tileMapByRegion: base.tileMapByRegion,
            sharedCandidateValidator: external,
          ),
        );
        expect(seen, same(external));
      },
    );
  });
}
