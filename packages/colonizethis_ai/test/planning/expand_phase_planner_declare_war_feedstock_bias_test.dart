// Unit tests for the EXPAND feedstock-tile acquisition declare-war target bias
// in `planExpandDeclareWar`
// (`packages/colonizethis_ai/lib/src/planning/expand_phase_planner.dart`)
// (Refs #2847 § H8-extraction seller feedstock-tile acquisition;
// SPEC/ai/economy-planner.md
// § EXPAND feedstock-tile acquisition declare-war target bias).
//
// This is the order-emission consumer of the topology-derived target
// `expandSellerFeedstockTileAcquisitionTarget`: when a flagged below-quota
// zero-NW lock-recovery seller has a conquest-reachable Old World feedstock
// province, the within-arm lexicographic declare-war tiebreak is redirected
// toward the faction owning that province — but only when that owner is one of
// the candidates in the arm that fires this turn. Arm precedence and every gate
// are unchanged, and the bias never fires for an unflagged GP, so the +6 Old
// World conquest baseline GPs (gp1/gp2) are never redirected.
//
// The flagged-seller fixture mirrors the one the logic detection / selection /
// target-wiring tests use: gp1 owns an unimproved `wool` regiment-build-input
// feedstock tile (so the improvement-input gate is active and it needs
// `lumber` / `castIron`) while owning no `timber` / `iron` tile (so the
// acquisition residual is active). Minor nations are then placed on the
// conquest frontier to shape which declare-war arm fires and which candidate is
// biased toward.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart'
    show sellerNeedsImprovementInputFeedstockTileAcquisition;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _sellerId = 'gp1';
const String _oldWorld = 'oldWorld';
const String _minor1 = 'minor1';
const String _minor2 = 'minor2';
const String _minor3 = 'minor3';

const String _grainTile = 'oldWorld|p0|0|0';
const String _woolTile = 'oldWorld|p0|2|0';

/// Builds the flagged below-quota zero-NW lock-recovery seller (`gp1`) plus the
/// supplied minor nations / provinces. `gp1` owns `oldWorld|p0..p4` (5 OW,
/// below the conquest quota), holds an unimproved `wool` tile (active
/// regiment-build-input improvement gate) and no `timber` / `iron` tile (active
/// acquisition residual), has zero New World provinces and zero regiments.
Game _game({
  required Map<String, String> resourceByTileKey,
  required List<Province> minorProvinces,
  required List<MinorNation> minorNations,
  int sellerTreasury = 0,
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
    id: 'g-2847-expand-feedstock-declare-war-bias',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [...sellerProvinces, ...minorProvinces],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: resourceByTileKey,
      tileState: TileMapState(),
    ),
    players: [
      Player(
        id: _sellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: sellerTreasury,
        stockpile: const Stockpile(),
      ),
    ],
    minorNations: minorNations,
  );
}

Province _minorProvince(String id, String ownerId) =>
    Province(id: id, regionId: _oldWorld, ownerId: ownerId);

AIWorldSnapshot _snapshot({
  required List<String> atWarWith,
  required List<String> invadableOw,
  List<String> adjacentOwners = const [],
}) {
  return AIWorldSnapshot(
    playerId: _sellerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 5,
      invadableProvinceIdsSorted: invadableOw,
      adjacentOwnerFactionIdsSorted: adjacentOwners,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group(
    'planExpandDeclareWar feedstock-tile acquisition target bias '
    '(Refs #2847 § EXPAND feedstock-tile acquisition declare-war target bias)',
    () {
      test(
        'arm 2 (already-at-war minors): biased to the feedstock-province owner '
        'over the lexicographically lower candidate',
        () {
          // minor1 < minor2 lexicographically; only minor2 owns the invadable
          // feedstock (`timber`) province. Without the bias arm 2 would pick
          // minor1; the bias must redirect to minor2.
          final game = _game(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              'oldWorld|m1|0|0': 'grain',
              'oldWorld|m2|0|0': 'timber',
            },
            minorProvinces: [
              _minorProvince('oldWorld|m1', _minor1),
              _minorProvince('oldWorld|m2', _minor2),
            ],
            minorNations: const [
              MinorNation(id: _minor1, displayName: 'M1'),
              MinorNation(id: _minor2, displayName: 'M2'),
            ],
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isTrue,
            reason: 'Precondition: the acquisition residual is active.',
          );
          final snapshot = _snapshot(
            atWarWith: const [_minor1, _minor2],
            invadableOw: const ['oldWorld|m1', 'oldWorld|m2'],
          );
          expect(
            planExpandDeclareWar(game: game, snapshot: snapshot),
            _minor2,
            reason:
                'Arm 2 fires (treasury 0, already-at-war minors on invadable '
                'OW). The within-arm tiebreak is biased to minor2 because it '
                'owns the conquest-reachable feedstock province, overriding '
                'the lexicographically lower minor1.',
          );
        },
      );

      test(
        'arm 1 (adjacent not-at-war minors): biased to the feedstock-province '
        'owner over the lexicographically lower candidate',
        () {
          final game = _game(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              'oldWorld|m1|0|0': 'grain',
              'oldWorld|m2|0|0': 'timber',
            },
            minorProvinces: [
              _minorProvince('oldWorld|m1', _minor1),
              _minorProvince('oldWorld|m2', _minor2),
            ],
            minorNations: const [
              MinorNation(id: _minor1, displayName: 'M1'),
              MinorNation(id: _minor2, displayName: 'M2'),
            ],
            sellerTreasury: 9999,
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isTrue,
            reason:
                'Precondition: the acquisition residual is active even with a '
                'funded treasury (the gate is treasury-independent).',
          );
          final snapshot = _snapshot(
            atWarWith: const [],
            invadableOw: const ['oldWorld|m1', 'oldWorld|m2'],
            adjacentOwners: const [_minor1, _minor2],
          );
          expect(
            planExpandDeclareWar(game: game, snapshot: snapshot),
            _minor2,
            reason:
                'Arm 1 fires (treasury >= cheapest, adjacent not-at-war minors '
                'on invadable OW). The within-arm tiebreak is biased to minor2 '
                'because it owns the conquest-reachable feedstock province.',
          );
        },
      );

      test(
        'acquisition residual inactive (baseline GP) -> no bias, '
        'lexicographic pick returned',
        () {
          // gp1 owns its own unimproved `timber` tile, so the routing gate
          // covers it and the acquisition residual is inactive. The bias must
          // not fire and arm 2 returns the lexicographically lowest candidate.
          final game = _game(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              'oldWorld|p0|1|0': 'timber',
              'oldWorld|m1|0|0': 'grain',
              'oldWorld|m2|0|0': 'timber',
            },
            minorProvinces: [
              _minorProvince('oldWorld|m1', _minor1),
              _minorProvince('oldWorld|m2', _minor2),
            ],
            minorNations: const [
              MinorNation(id: _minor1, displayName: 'M1'),
              MinorNation(id: _minor2, displayName: 'M2'),
            ],
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isFalse,
            reason: 'Precondition: the acquisition residual is inactive.',
          );
          final snapshot = _snapshot(
            atWarWith: const [_minor1, _minor2],
            invadableOw: const ['oldWorld|m1', 'oldWorld|m2'],
          );
          expect(
            planExpandDeclareWar(game: game, snapshot: snapshot),
            _minor1,
            reason:
                'With the residual inactive, '
                'expandSellerFeedstockTileAcquisitionTarget returns null, so '
                'the unbiased lexicographic pick (minor1) is returned. The +6 '
                'OW conquest baseline GPs are never redirected.',
          );
        },
      );

      test(
        'feedstock owner sits in a lower-priority arm -> bias does not cross '
        'arm precedence',
        () {
          // Arm 1 fires on adjacent not-at-war minors minor1/minor2 (grain
          // only). The only feedstock province is owned by the at-war minor3
          // (arm 2). The bias must NOT cross arm precedence: arm 1 returns its
          // lexicographically lowest candidate (minor1).
          final game = _game(
            resourceByTileKey: const {
              _grainTile: 'grain',
              _woolTile: 'wool',
              'oldWorld|m1|0|0': 'grain',
              'oldWorld|m2|0|0': 'grain',
              'oldWorld|m3|0|0': 'timber',
            },
            minorProvinces: [
              _minorProvince('oldWorld|m1', _minor1),
              _minorProvince('oldWorld|m2', _minor2),
              _minorProvince('oldWorld|m3', _minor3),
            ],
            minorNations: const [
              MinorNation(id: _minor1, displayName: 'M1'),
              MinorNation(id: _minor2, displayName: 'M2'),
              MinorNation(id: _minor3, displayName: 'M3'),
            ],
            sellerTreasury: 9999,
          );
          expect(
            sellerNeedsImprovementInputFeedstockTileAcquisition(game, _sellerId),
            isTrue,
          );
          final snapshot = _snapshot(
            atWarWith: const [_minor3],
            invadableOw: const ['oldWorld|m1', 'oldWorld|m2', 'oldWorld|m3'],
            adjacentOwners: const [_minor1, _minor2],
          );
          expect(
            planExpandDeclareWar(game: game, snapshot: snapshot),
            _minor1,
            reason:
                'Arm 1 (adjacent not-at-war minor1/minor2) fires first. The '
                'feedstock owner minor3 belongs to the lower-priority arm 2, '
                'so it is not an arm-1 candidate: the bias only redirects '
                'within the firing arm and returns minor1.',
          );
        },
      );

      test('determinism: identical inputs yield identical output', () {
        final game = _game(
          resourceByTileKey: const {
            _grainTile: 'grain',
            _woolTile: 'wool',
            'oldWorld|m1|0|0': 'grain',
            'oldWorld|m2|0|0': 'timber',
          },
          minorProvinces: [
            _minorProvince('oldWorld|m1', _minor1),
            _minorProvince('oldWorld|m2', _minor2),
          ],
          minorNations: const [
            MinorNation(id: _minor1, displayName: 'M1'),
            MinorNation(id: _minor2, displayName: 'M2'),
          ],
        );
        final snapshot = _snapshot(
          atWarWith: const [_minor1, _minor2],
          invadableOw: const ['oldWorld|m1', 'oldWorld|m2'],
        );
        final first = planExpandDeclareWar(game: game, snapshot: snapshot);
        final second = planExpandDeclareWar(game: game, snapshot: snapshot);
        expect(first, _minor2);
        expect(second, _minor2, reason: 'Same inputs -> same output.');
      });
    },
  );
}
