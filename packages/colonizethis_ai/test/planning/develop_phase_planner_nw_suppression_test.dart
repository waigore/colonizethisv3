// Module-level NW-suppression pin for the DEVELOP phase planner set
// (Refs #2509 S4 / S10 / S6 phase-planner-architecture sub-spec).
//
// Spec contract (issue #2509 § Phase planner unit tests § "DEVELOP NW
// suppression"; SPEC/ai/phase-planner-architecture.md § Acceptance
// criteria):
//
//   "Given a GP in DEVELOP, when its phase-planner orders are
//    collected, then the result contains zero declareWar, NW
//    acquisition, or NW invasion orders."
//
// The DEVELOP phase planner set is intentionally minimal: exactly two
// pure-function contracts (`planDevelopPeace`, `planDevelopCivilian`)
// per the phase-planner-architecture table. Structural suppression
// for DEVELOP is twofold:
//
//   1. **Module API surface:** DEVELOP exposes no `declareWar`, no
//      acquisition (Join Empire / purchase_land), and no military /
//      naval planner. New wars are structurally impossible because
//      no function in the module returns a declare-war target. NW
//      acquisition is structurally impossible because no function
//      returns acquisition targets.
//   2. **Per-function NW restrictions:** `planDevelopPeace` returns
//      `offerPeace` targets only (the function name and return
//      contract make declareWar emission impossible from this
//      module). `planDevelopCivilian` emits `build_improvement`
//      orders only, exclusively on tiles inside provinces the active
//      player owns — `purchase_land` toward unowned NW tiles and
//      `build_improvement` toward foreign / tribe-held NW land are
//      both structurally suppressed by the ownership gate.
//
// Per-function pins for `planDevelopPeace` and `planDevelopCivilian`
// already live in `develop_phase_planner_test.dart` (the GP filter,
// the foreign-ownership exclusion, etc.). This file is the AC pin
// for the **planner set as a whole**: it exercises both functions
// on a single shared fixture that loads every NW signal slot the
// orchestrator (#2509 S5) will eventually route through, then
// asserts that the merged output set carries no NW-acquisition or
// declareWar surface.
//
// Why a planner-set integration pin in addition to per-function pins:
//   - The per-function pins prove each contract individually never
//     emits NW unowned-tile orders. The planner-set pin proves the
//     **composition** of the two planners is also free of NW
//     leakage — for example a future refactor that broadens
//     `planDevelopCivilian` to read tribe-owned NW provinces from
//     the snapshot's `ColonialSummary` would be exercised here once.
//   - The AC ("when its phase-planner orders are collected") is
//     explicitly the planner set, not a single function. Pinning
//     that wording at the library level keeps the AC verifiable
//     today, before the S5 orchestrator wiring lands.
//   - The fixture explicitly includes tribe-owned NW provinces, an
//     owned NW province with a resource tile, and tribe / minor
//     factions in `atWarWith` — every surface a DEVELOP planner
//     could possibly leak through.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/develop_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

const String _gp1OwProvinceId = 'oldWorld|gp1_a';
const String _gp1NwProvinceId = 'newWorld|gp1_a';
const String _tribeNwProvinceId = 'newWorld|tribe1_a';
const String _unownedNwProvinceId = 'newWorld|p_unowned';

/// Owned-OW tile (active player can improve).
const String _ownedOwTileKey = 'oldWorld|gp1_a|3|3';

/// Owned-NW tile (active player can improve — NW IS allowed for
/// DEVELOP since the gate is ownership, not region).
const String _ownedNwTileKey = 'newWorld|gp1_a|4|4';

/// Tribe-held NW tile (foreign ownership; planner must structurally
/// reject this even though it carries a resource entry).
const String _tribeNwTileKey = 'newWorld|tribe1_a|2|2';

/// Unowned NW tile (no owner / no tribe; planner must structurally
/// reject this even though it carries a resource entry).
const String _unownedNwTileKey = 'newWorld|p_unowned|1|1';

/// Build a Game scaffold for the planner-set AC pin:
///   - Active player ([_gp1]) owns one OW and one NW province so
///     `planDevelopCivilian` has eligible tiles in both regions; this
///     proves the planner emits orders for OW + owned-NW (positive
///     coverage path) while rejecting foreign / unowned NW (the AC
///     suppression).
///   - Tribe ([_tribe1]) owns a NW province with a resource tile —
///     the structural NW-acquisition leakage surface.
///   - A second NW province is left unowned with a resource tile —
///     the structural `purchase_land` leakage surface.
///   - One idle Builder belongs to the active player.
Game _developGame({int turnNumber = 145}) {
  return Game(
    id: 'g-2509-develop-phase-planner-nw-suppression-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: _gp1OwProvinceId,
            regionId: kOldWorldRegionId,
            ownerId: _gp1,
          ),
        ],
        units: [
          // Two idle builders so the `min(builders, eligibleTiles)`
          // cap is 2 and the planner emits orders for BOTH owned
          // tiles (OW + owned-NW). The single-builder case is
          // already pinned in `develop_phase_planner_test.dart` —
          // here we want full eligible-tile coverage so the
          // suppression check exercises every tile the planner
          // walks.
          Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
            ownerId: _gp1,
            locationProvinceId: _gp1OwProvinceId,
            tileKey: '$_gp1OwProvinceId|9|9',
          ),
          Unit(
            id: 'b2',
            type: kUnitTypeBuilder,
            ownerId: _gp1,
            locationProvinceId: _gp1OwProvinceId,
            tileKey: '$_gp1OwProvinceId|8|8',
          ),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: _gp1NwProvinceId,
            regionId: kNewWorldRegionId,
            ownerId: _gp1,
          ),
          Province(
            id: _tribeNwProvinceId,
            regionId: kNewWorldRegionId,
            ownerId: _tribe1,
          ),
          Province(id: _unownedNwProvinceId, regionId: kNewWorldRegionId),
        ],
      ),
      // Every NW tile slot the planner-set could possibly leak
      // through carries a resource entry so resource-availability is
      // never the gating filter — only ownership / region structure
      // can keep NW-acquisition out of the output.
      resourceByTileKey: const {
        _ownedOwTileKey: 'grain',
        _ownedNwTileKey: 'tobacco',
        _tribeNwTileKey: 'spices',
        _unownedNwTileKey: 'gold',
      },
    ),
    players: const [
      Player(id: _gp1, displayName: 'GP1', isHuman: false),
      Player(id: _gp2, displayName: 'GP2', isHuman: false),
      Player(id: _gp3, displayName: 'GP3', isHuman: false),
    ],
    tribes: const [Tribe(id: _tribe1, displayName: 'Tribe1')],
    minorNations: const [MinorNation(id: _minor1, displayName: 'Minor1')],
  );
}

/// Snapshot for DEVELOP posture: OW at quota (10), no visible
/// colonial acquisition targets in conquest summary (DEVELOP routing
/// requires `hasColonialAcquisitionTargets == false`), `atWarWith`
/// includes both GPs (to exercise peace), a tribe, and a minor (to
/// exercise the non-GP filter in `planDevelopPeace`).
///
/// `ColonialSummary` is populated with NW tribe-owned and unowned
/// invadable provinces so the planner-set has live NW state to lean
/// on if any suppression slipped — the AC explicitly says the
/// planner set must not emit NW-acquisition / declareWar even when
/// colonial signals are present.
AIWorldSnapshot _developSnapshot({
  List<String> atWarWith = const [_gp2, _gp3, _tribe1, _minor1],
}) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
    ),
    colonial: const ColonialSummary(
      newWorldProvincesOwned: 1,
      invadableNewWorldProvinceIdsSorted: [
        _tribeNwProvinceId,
        _unownedNwProvinceId,
      ],
      adjacentNewWorldOwnerFactionIdsSorted: [_tribe1],
      preferredColonialTargetFactionIdsSorted: [_tribe1],
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// Whether [provinceId] is in the New World region.
bool _isNwProvinceId(String provinceId) =>
    ProvinceId.regionIdFrom(provinceId) == kNewWorldRegionId;

/// Boolean test for whether [factionId] resolves to a tribe or minor
/// nation in [game] (a non-Great-Power faction whose presence in
/// DEVELOP peace output would indicate structural leakage).
bool _isNonGpFaction(Game game, String factionId) {
  if (game.tribes.any((t) => t.id == factionId)) return true;
  if (game.minorNations.any((m) => m.id == factionId)) return true;
  return false;
}

/// Owner of the province that contains [tileKey] in [game], or `null`
/// when the province is not found.
String? _ownerOfProvinceContainingTile(Game game, String tileKey) {
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  if (provinceId == null) return null;
  for (final region in <RegionData>[
    game.worldState.oldWorld,
    game.worldState.newWorld,
  ]) {
    for (final p in region.provinces) {
      if (p.id == provinceId) return p.ownerId;
    }
  }
  return null;
}

void main() {
  group('DEVELOP planner set NW suppression (AC pin)', () {
    test('planner set output contains no declareWar, no NW acquisition, '
        'and no NW-invasion orders', () {
      final game = _developGame();
      final snapshot = _developSnapshot();

      // 1. planDevelopPeace: returns offerPeace targets (GP
      //    factionIds), never a declareWar emission. The function
      //    contract is "List<String>" of peace targets, so a
      //    declareWar leakage is structurally impossible from this
      //    module — there is no acquisition / declare-war function
      //    on develop_phase_planner.dart to call. Pin: every entry
      //    is a Great Power factionId (tribes / minors filtered).
      final peace = planDevelopPeace(game: game, snapshot: snapshot);
      for (final factionId in peace) {
        expect(
          _isNonGpFaction(game, factionId),
          isFalse,
          reason:
              'planDevelopPeace must return only Great Power '
              'factionIds (DEVELOP is GP-vs-GP peace only). Tribe / '
              'minor ids in the output set indicate a structural '
              'leakage that would route the orchestrator into an '
              'unsupported NW peace path. Offending factionId: '
              '$factionId.',
        );
      }
      // Positive coverage: both at-war GPs appear so we know the
      // planner is exercising live data, not the empty short-
      // circuit (the AC pin would otherwise be tautological).
      expect(peace, containsAll(<String>[_gp2, _gp3]));

      // 2. planDevelopCivilian: emits only `build_improvement`
      //    orders (target field is always
      //    `kWorkTargetBuildImprovement`). NW-acquisition surfaces
      //    that the AC suppresses (`purchase_land`) are
      //    structurally impossible because the function never sets
      //    `target` to anything else. Tile selection only walks
      //    `resourceByTileKey` and filters to owned provinces, so
      //    foreign / unowned NW tiles cannot land in the output.
      final civilian = planDevelopCivilian(game: game, snapshot: snapshot);
      for (final order in civilian) {
        expect(
          order.target,
          kWorkTargetBuildImprovement,
          reason:
              'planDevelopCivilian must emit only '
              'kWorkTargetBuildImprovement orders. Any other target '
              '(purchase_land, etc.) is a structural NW-acquisition '
              'leakage. Offending order: $order.',
        );
        // Foreign-owned or unowned NW tiles must never appear in
        // the output. This guards against a future refactor that
        // broadens `resourceByTileKey` walking past the ownership
        // gate.
        final tileOwner = _ownerOfProvinceContainingTile(
          game,
          order.targetTileKey,
        );
        expect(
          tileOwner,
          _gp1,
          reason:
              'planDevelopCivilian emitted a build_improvement '
              'order against tile ${order.targetTileKey} whose '
              'province is owned by $tileOwner (not the active '
              'player). DEVELOP must improve owned territory only; '
              'tile-keys in foreign or unowned provinces are a '
              'structural NW-acquisition leakage.',
        );
      }
      // Positive coverage: both owned tiles (OW + owned-NW) ranked
      // and emitted so the test exercises the full eligible-tile
      // sort rather than the empty short-circuit. NW score >
      // OW score, so owned-NW comes first.
      expect(civilian.map((o) => o.targetTileKey), <String>[
        _ownedNwTileKey,
        _ownedOwTileKey,
      ]);

      // 3. Structural NW-tile rejection pin: even though the
      //    fixture includes tribe-owned and unowned NW tiles with
      //    resource entries, those tile keys must never appear in
      //    the planner-set output. Tests the ownership gate from
      //    the negative side.
      final emittedTileKeys = civilian.map((o) => o.targetTileKey).toSet();
      expect(
        emittedTileKeys.contains(_tribeNwTileKey),
        isFalse,
        reason:
            'planDevelopCivilian must not emit improvements toward '
            'tribe-held NW tiles. The tribe-NW tile resource entry '
            'is present in the fixture; rejection must come from '
            'the ownership gate (province.ownerId != playerId).',
      );
      expect(
        emittedTileKeys.contains(_unownedNwTileKey),
        isFalse,
        reason:
            'planDevelopCivilian must not emit improvements toward '
            'unowned NW tiles. The unowned-NW tile resource entry '
            'is present in the fixture; rejection must come from '
            'the ownership gate (province.ownerId is null and not '
            'the active player).',
      );
    });

    test('tribe-only at-war set (NW-acquisition tempting) -> peace empty, '
        'civilian unchanged (no NW leakage when only tribes are at war)', () {
      // Tightens the AC: when the ONLY at-war factions are
      // non-Great-Power (tribes + minors), `planDevelopPeace` must
      // return empty (GP filter drops every entry) AND
      // `planDevelopCivilian` must still emit only owned-tile
      // improvements (no NW-acquisition leakage even though tribes
      // hold visible NW provinces).
      final game = _developGame();
      final snapshot = _developSnapshot(atWarWith: const [_tribe1, _minor1]);

      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'planDevelopPeace must return empty when atWarWith '
            'contains only non-GP factions. A tribe / minor id in '
            'the output set would route the orchestrator into an '
            'unsupported NW peace path.',
      );

      final civilian = planDevelopCivilian(game: game, snapshot: snapshot);
      for (final order in civilian) {
        expect(order.target, kWorkTargetBuildImprovement);
        expect(
          _isNwProvinceId(order.targetTileKey) &&
              _ownerOfProvinceContainingTile(game, order.targetTileKey) != _gp1,
          isFalse,
          reason:
              'planDevelopCivilian must never emit a NW order '
              'against a tile in a province the active player does '
              'not own, regardless of `atWarWith` shape. Offending '
              'order: $order.',
        );
      }
    });

    test('colonial summary populated but DEVELOP still routes only to '
        'owned-tile improvements (positive structural NW pin)', () {
      // Positive structural pin: `ColonialSummary` carries
      // `invadableNewWorldProvinceIdsSorted` with both tribe-held
      // and unowned NW provinces. Neither `planDevelopPeace` nor
      // `planDevelopCivilian` reads the colonial summary — the
      // suppression is structural via the module's import surface
      // and per-function contracts. This test exercises the full
      // planner-set output against a NW-loaded colonial summary
      // and pins that the only NW tile in the output (if any) is
      // the active player's owned NW tile.
      final game = _developGame();
      final snapshot = _developSnapshot();
      // Re-affirm the colonial summary is populated (test fixture
      // contract — guards against silent fixture drift).
      expect(snapshot.colonial.invadableNewWorldProvinceIdsSorted, isNotEmpty);

      final civilian = planDevelopCivilian(game: game, snapshot: snapshot);
      final nwOrders = civilian
          .where((o) => _isNwProvinceId(o.targetTileKey))
          .toList();
      expect(
        nwOrders.length,
        1,
        reason:
            'Exactly one NW order should appear (the active '
            'player owns one NW province with one resource tile). '
            'A larger NW count would indicate leakage from the '
            'colonial summary into civilian planning.',
      );
      expect(nwOrders.single.targetTileKey, _ownedNwTileKey);
    });

    test('determinism across the planner set (Must-have #7): same '
        'NW-rich fixture -> identical plan outputs across two runs', () {
      // Pins the per-function determinism contract at the
      // planner-set level: both planners must remain pure functions
      // even when called together in the orchestrator dispatch
      // order. A regression that cached state across calls would
      // surface here.
      final game = _developGame();
      final snapshot = _developSnapshot();

      final peace1 = planDevelopPeace(game: game, snapshot: snapshot);
      final civilian1 = planDevelopCivilian(game: game, snapshot: snapshot);

      final peace2 = planDevelopPeace(game: game, snapshot: snapshot);
      final civilian2 = planDevelopCivilian(game: game, snapshot: snapshot);

      expect(peace2, peace1);
      expect(
        civilian2.map((o) => '${o.unitId}->${o.targetTileKey}').toList(),
        civilian1.map((o) => '${o.unitId}->${o.targetTileKey}').toList(),
      );
    });
  });
}
