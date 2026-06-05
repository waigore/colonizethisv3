// Unit tests for `expandSellerFeedstockTileAcquisitionTarget` in
// `packages/colonizethis_ai/lib/src/planning/expand_phase_planner_feedstock_acquisition.dart`
// (Refs #2847 § H8-extraction seller feedstock-tile acquisition target wiring;
// SPEC/ai/economy-planner.md § EXPAND feedstock-tile acquisition target wiring).
//
// The function is the AI-side wiring for the topology-free logic pick contract
// `sellerFeedstockTileAcquisitionTarget`: it treats the EXPAND conquest frontier
// (`snapshot.conquest.invadableProvinceIdsSorted`) as the acquirable target set
// and returns the deterministic primary Old World feedstock-bearing province the
// flagged below-quota zero-NW lock-recovery seller should pursue by conquest, or
// `null` when none applies.
//
// Reuses the below-quota zero-NW lock-recovery seller fixture the logic
// detection / selection tests use (gp1 owns an unimproved `wool`
// regiment-build-input feedstock tile so the improvement-input gate is active
// and it needs `lumber` / `castIron`, while owning no `timber` / `iron` tile so
// the acquisition residual is active), then shapes the conquest frontier on the
// snapshot to control which acquisition candidates are reachable this turn.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _sellerId = 'gp1';
const String _oldWorld = 'oldWorld';
const String _newWorld = 'newWorld';

const String _grainTile = 'oldWorld|p0|0|0';
const String _woolTile = 'oldWorld|p0|2|0';

Game _flaggedSellerGame({
  Map<String, String> resourceByTileKey = const {
    _grainTile: 'grain',
    _woolTile: 'wool',
  },
  List<Province> extraOldWorld = const [],
  List<Province> extraNewWorld = const [],
  TileMapState? tileState,
}) {
  final sellerProvinces = List.generate(
    5,
    (i) => Province(
      id: 'oldWorld|p$i',
      regionId: _oldWorld,
      ownerId: _sellerId,
    ),
  );
  return Game(
    id: 'g-2847-expand-feedstock-acquisition',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: [...sellerProvinces, ...extraOldWorld]),
      newWorld: RegionData(provinces: extraNewWorld),
      resourceByTileKey: resourceByTileKey,
      tileState: tileState ?? TileMapState(),
    ),
    players: const [
      Player(
        id: _sellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: 0,
        stockpile: Stockpile(),
      ),
    ],
  );
}

Province _tribeProvince(String id, {String region = _oldWorld}) =>
    Province(id: id, regionId: region, ownerId: 'tribe1');

AIWorldSnapshot _snapshot({
  required List<String> invadableOw,
  String playerId = _sellerId,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(atWarWith: []),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 5,
      invadableProvinceIdsSorted: invadableOw,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group(
    'expandSellerFeedstockTileAcquisitionTarget '
    '(Refs #2847 H8-extraction EXPAND feedstock-tile acquisition target wiring)',
    () {
      test(
        'returns the conquest-reachable feedstock province when the flagged '
        'seller can invade it',
        () {
          final game = _flaggedSellerGame(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              'oldWorld|t1|0|0': 'timber',
            },
            extraOldWorld: [_tribeProvince('oldWorld|t1')],
          );
          // Precondition: the acquisition residual is active for the seller.
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isTrue,
          );
          final snapshot = _snapshot(invadableOw: const ['oldWorld|t1']);
          expect(
            expandSellerFeedstockTileAcquisitionTarget(
              game: game,
              snapshot: snapshot,
            ),
            equals('oldWorld|t1'),
          );
        },
      );

      test(
        'returns the lowest conquest-reachable feedstock province id when '
        'several are invadable',
        () {
          final game = _flaggedSellerGame(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              'oldWorld|t2|0|0': 'timber',
              'oldWorld|t1|0|0': 'iron',
            },
            extraOldWorld: [
              _tribeProvince('oldWorld|t2'),
              _tribeProvince('oldWorld|t1'),
            ],
          );
          final snapshot = _snapshot(
            invadableOw: const ['oldWorld|t2', 'oldWorld|t1'],
          );
          expect(
            expandSellerFeedstockTileAcquisitionTarget(
              game: game,
              snapshot: snapshot,
            ),
            equals('oldWorld|t1'),
          );
        },
      );

      test(
        'returns null when the feedstock province is not on the conquest '
        'frontier (cannot be reached this turn)',
        () {
          final game = _flaggedSellerGame(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              'oldWorld|t1|0|0': 'timber',
            },
            extraOldWorld: [_tribeProvince('oldWorld|t1')],
          );
          // Disjoint conquest frontier: the feedstock province is not invadable.
          final snapshot = _snapshot(invadableOw: const ['oldWorld|t9']);
          expect(
            expandSellerFeedstockTileAcquisitionTarget(
              game: game,
              snapshot: snapshot,
            ),
            isNull,
          );
        },
      );

      test('returns null when the conquest frontier is empty', () {
        final game = _flaggedSellerGame(
          resourceByTileKey: const {
            _grainTile: 'grain',
            _woolTile: 'wool',
            'oldWorld|t1|0|0': 'timber',
          },
          extraOldWorld: [_tribeProvince('oldWorld|t1')],
        );
        final snapshot = _snapshot(invadableOw: const []);
        expect(
          expandSellerFeedstockTileAcquisitionTarget(
            game: game,
            snapshot: snapshot,
          ),
          isNull,
        );
      });

      test(
        'returns null when the acquisition residual is inactive even though a '
        'feedstock province is invadable (baseline GPs never targeted)',
        () {
          // The seller owns its own unimproved timber tile, so the routing gate
          // covers it and the acquisition residual is inactive.
          final game = _flaggedSellerGame(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              'oldWorld|p0|1|0': 'timber',
              'oldWorld|t1|0|0': 'timber',
            },
            extraOldWorld: [_tribeProvince('oldWorld|t1')],
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isFalse,
          );
          final snapshot = _snapshot(invadableOw: const ['oldWorld|t1']);
          expect(
            expandSellerFeedstockTileAcquisitionTarget(
              game: game,
              snapshot: snapshot,
            ),
            isNull,
          );
        },
      );

      test('evaluation is deterministic', () {
        final game = _flaggedSellerGame(
          resourceByTileKey: const {
            _grainTile: 'grain',
            _woolTile: 'wool',
            'oldWorld|t2|0|0': 'timber',
            'oldWorld|t1|0|0': 'iron',
          },
          extraOldWorld: [
            _tribeProvince('oldWorld|t2'),
            _tribeProvince('oldWorld|t1'),
          ],
        );
        final snapshot = _snapshot(
          invadableOw: const ['oldWorld|t1', 'oldWorld|t2'],
        );
        final a = expandSellerFeedstockTileAcquisitionTarget(
          game: game,
          snapshot: snapshot,
        );
        final b = expandSellerFeedstockTileAcquisitionTarget(
          game: game,
          snapshot: snapshot,
        );
        expect(a, equals(b));
        expect(a, equals('oldWorld|t1'));
      });

      test(
        'New World feedstock provinces are excluded from the conquest-frontier '
        'pick',
        () {
          // Even if a New World feedstock province is somehow on the frontier,
          // the logic contract excludes New World, so the pick is null.
          final game = _flaggedSellerGame(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              'newWorld|n1|0|0': 'timber',
            },
            extraNewWorld: [
              _tribeProvince('newWorld|n1', region: _newWorld),
            ],
          );
          final snapshot = _snapshot(invadableOw: const ['newWorld|n1']);
          expect(
            expandSellerFeedstockTileAcquisitionTarget(
              game: game,
              snapshot: snapshot,
            ),
            isNull,
          );
        },
      );
    },
  );
}
