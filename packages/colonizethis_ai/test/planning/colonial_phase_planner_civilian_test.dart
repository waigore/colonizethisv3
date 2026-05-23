// Unit tests for the COLONIAL-phase civilian contract in
// `packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`
// (Refs #2509 S3 / S10).
//
// Spec contract (issue #2509 § COLONIAL phase planner § planColonialCivilian,
// also § Suppressions in COLONIAL "No OW build_improvement except tiles
// needed for port/supply to active NW objectives"):
//
//   "Returns: List<WorkOrder> (NW purchase_land, NW improvements)."
//
// This slice covers the **NW improvements** half of that contract. The
// OW port/supply allowance and the `purchase_land` half are deferred to
// follow-up slices (`planColonialAcquisition` for purchase_land, a
// targeted OW port-supply broadening once active-NW-objective state is
// available from the orchestrator). Suppressing OW improvements
// unconditionally here matches the structural COLONIAL-phase default
// the spec mandates and parallels the pin pattern established for
// `planDevelopCivilian` in `develop_phase_planner_test.dart`.
//
// `planColonialCivilian` tests:
//   1. **No owned NW provinces:** active player owns zero NW provinces
//      -> empty list (NW ownership is the outermost structural gate; a
//      regression that scanned without it would emit improvement orders
//      toward foreign NW territory and fail validation).
//   2. **No idle Builders:** owned NW province with an unimproved
//      resource tile but no idle Builder units -> empty list (no
//      builder, no order).
//   3. **OW resource tile excluded (structural NW restriction):** the
//      planner must skip every tile in the Old World region even when
//      the active player owns the province and the tile carries a
//      resource; pins the COLONIAL Suppressions rule "No OW
//      build_improvement except ..." in its default form.
//   4. **Foreign NW tile excluded:** a resource tile in a NW province
//      owned by another GP must not appear in the output (ownership
//      filter pins the spec contract).
//   5. **Town tile excluded with resource entry:** `townTileKey`
//      exclusion pins the spec rule "Exclude capital tiles and town
//      tiles (no resources)"; even when a (synthetic) world state pairs
//      a resource with a town tile the planner must skip it.
//   6. **Already-improved NW tile excluded:** `improvementLevel >= 1`
//      gate must drop tiles already at improvement level 1+ (a
//      regression that re-emitted toward such tiles would waste a
//      Builder cycle).
//   7. **Builder-to-tile cap (`min(builders, tiles)`):** two tiles, one
//      idle Builder -> exactly one order on the lex-first builder id.
//   8. **Tile-to-builder cap (`min(builders, tiles)` reverse):** two
//      idle Builders, one tile -> exactly one order bound to the
//      lex-first builder id.
//   9. **Multiple eligible NW tiles, lex tie-break:** all eligible
//      tiles have the uniform NW-owned score in the current
//      implementation; ties break lex ascending by tile key.
//  10. **Working / non-Builder unit skipped:** `status == working`
//      Builders and idle non-Builder civilians (e.g. Merchant) must be
//      excluded from the builder roster.
//  11. **Determinism (Must-have #7):** identical inputs yield byte-
//      identical orders across repeated calls.
//
// This file is the in-module pin for `planColonialCivilian`. There is
// no legacy helper to reconcile with: civilian work today flows through
// the `selectFullAiCivilianWorkOrders` pipeline in `colonizethis_logic`,
// which the S5 orchestrator refactor will replace with phase-planner
// dispatch.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';

// Province ids laid out per SPEC/game/world-model-identity.md. The
// region prefix doubles as the tile-key region segment, so deriving
// region / province ids from a tile key (per [Unit.regionIdFromTileKey],
// [Unit.provinceIdFromTileKey]) matches the canonical ids in the
// fixtures.
const String _owProv1 = 'oldWorld|p_alpha';
const String _nwProv1 = 'newWorld|p_gamma';
const String _nwProv2 = 'newWorld|p_delta';
const String _nwForeignProv = 'newWorld|p_foreign';

// Tile keys: regionId|provinceId|x|y. Province id is derived back out
// via [Unit.provinceIdFromTileKey], so keys must match the owned
// province ids byte-for-byte. Town tile fixtures intentionally use
// `|0|0` so a regression that ignores the `townTileKey` filter would
// have to confront a deterministic same-shape sibling tile.
const String _owTileA = 'oldWorld|p_alpha|1|1';
const String _nwTileA = 'newWorld|p_gamma|1|1';
const String _nwTileB = 'newWorld|p_gamma|2|2';
const String _nwTileC = 'newWorld|p_delta|3|3';
const String _nwTileTown = 'newWorld|p_gamma|0|0';
const String _nwTileImproved = 'newWorld|p_delta|9|9';
const String _nwForeignTile = 'newWorld|p_foreign|5|5';

Game _civilianGame({
  required List<Province> provinces,
  required List<Unit> owUnits,
  List<Unit> nwUnits = const [],
  Map<String, String> resourceByTileKey = const {},
  TileMapState tileState = const TileMapState(),
}) {
  final byRegion = <String, List<Province>>{};
  for (final province in provinces) {
    byRegion.putIfAbsent(province.regionId, () => <Province>[]).add(province);
  }
  return Game(
    id: 'g-2509-colonial-phase-planner-civilian',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 132, phase: TurnPhase.orders),
      oldWorld: RegionData(
        provinces: byRegion[kOldWorldRegionId] ?? const [],
        units: owUnits,
      ),
      newWorld: RegionData(
        provinces: byRegion[kNewWorldRegionId] ?? const [],
        units: nwUnits,
      ),
      resourceByTileKey: resourceByTileKey,
      tileState: tileState,
    ),
    players: const [
      Player(id: _gp1, displayName: 'GP1', isHuman: false),
      Player(id: _gp2, displayName: 'GP2', isHuman: false),
    ],
  );
}

/// Minimal snapshot with the active player [_gp1]. The planner does not
/// re-check the phase, so phase-routing fields (`conquest`, `colonial`)
/// stay empty; the in-module contract is what these tests pin.
AIWorldSnapshot _civilianSnapshot() {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: const ThreatSummary(atWarWith: []),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

Unit _idleBuilder(String id, {String regionId = kOldWorldRegionId}) {
  final provinceId = regionId == kOldWorldRegionId ? _owProv1 : _nwProv1;
  return Unit(
    id: id,
    type: kUnitTypeBuilder,
    ownerId: _gp1,
    locationProvinceId: provinceId,
    tileKey: '$provinceId|9|9',
  );
}

void main() {
  group('planColonialCivilian', () {
    test('no owned NW provinces -> empty', () {
      // Active player owns an OW province with an unimproved resource
      // tile, but no NW provinces. NW ownership is the outermost
      // structural gate for the COLONIAL civilian contract: a
      // regression that scanned `resourceByTileKey` without the
      // NW-province-ownership filter would emit `build_improvement`
      // toward OW tiles in violation of the COLONIAL Suppressions
      // rule ("No OW build_improvement except port/supply").
      final game = _civilianGame(
        provinces: const [
          Province(id: _owProv1, regionId: kOldWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [_idleBuilder('b1')],
        resourceByTileKey: const {_owTileA: 'grain'},
      );
      expect(
        planColonialCivilian(game: game, snapshot: _civilianSnapshot()),
        isEmpty,
        reason:
            'Active player owns zero NW provinces -> no eligible tiles. '
            'The COLONIAL civilian planner must short-circuit before '
            'scanning resource tiles when the owned-NW set is empty.',
      );
    });

    test('no idle builders -> empty', () {
      // Active player owns a NW province with an unimproved resource
      // tile, but no Builder units exist. A regression that emitted a
      // `build_improvement` order without a builder would fail unit
      // assignment validation downstream.
      final game = _civilianGame(
        provinces: const [
          Province(id: _nwProv1, regionId: kNewWorldRegionId, ownerId: _gp1),
        ],
        owUnits: const [],
        resourceByTileKey: const {_nwTileA: 'tobacco'},
      );
      expect(
        planColonialCivilian(game: game, snapshot: _civilianSnapshot()),
        isEmpty,
        reason:
            'No idle Builders -> no orders. The function must skip its '
            'tile scan when builders are empty (early-exit contract).',
      );
    });

    test('OW resource tile excluded even when owned (NW-only restriction)', () {
      // Active player owns both an OW province (with an unimproved
      // resource tile) and a NW province (with no resource tile). The
      // OW resource tile must not appear in the output: this is the
      // structural COLONIAL Suppressions rule "No OW build_improvement
      // except tiles needed for port/supply to active NW objectives"
      // in its default form (no active-NW-objective set is yet wired,
      // so the planner suppresses OW improvements unconditionally).
      final game = _civilianGame(
        provinces: const [
          Province(id: _owProv1, regionId: kOldWorldRegionId, ownerId: _gp1),
          Province(id: _nwProv1, regionId: kNewWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [_idleBuilder('b1')],
        resourceByTileKey: const {_owTileA: 'grain'},
      );
      expect(
        planColonialCivilian(game: game, snapshot: _civilianSnapshot()),
        isEmpty,
        reason:
            'OW resource tile is structurally suppressed in COLONIAL. '
            'A regression that emitted an OW order here would break '
            'the COLONIAL Suppressions rule and overlap with '
            '`planExpandEconomy` / `planDevelopCivilian` responsibilities.',
      );
    });

    test('foreign-owned NW tile excluded from output', () {
      // Province ownership is a structural gate: a NW province owned
      // by another GP must not appear in the output even when its
      // tiles carry rich resources. A regression that scanned
      // `resourceByTileKey` without the province-ownership filter
      // would route the lone Builder onto a foreign NW tile.
      final game = _civilianGame(
        provinces: const [
          Province(id: _nwProv1, regionId: kNewWorldRegionId, ownerId: _gp1),
          Province(
            id: _nwForeignProv,
            regionId: kNewWorldRegionId,
            ownerId: _gp2,
          ),
        ],
        owUnits: [_idleBuilder('b1')],
        resourceByTileKey: const {_nwForeignTile: 'gold', _nwTileA: 'tobacco'},
      );
      final orders = planColonialCivilian(
        game: game,
        snapshot: _civilianSnapshot(),
      );
      expect(orders.map((o) => o.targetTileKey), const [_nwTileA]);
    });

    test('town tile is excluded even with resource entry', () {
      // `townTileKey` exclusion pins the spec rule "Exclude capital
      // tiles and province town tiles (no resources)". Even when the
      // (synthetic) world state pairs a resource with a town tile, the
      // planner must skip it; relying on `resourceByTileKey` alone
      // would permit a regression that places a resource on a town
      // tile and emits an improvement order against the town.
      final game = _civilianGame(
        provinces: const [
          Province(
            id: _nwProv1,
            regionId: kNewWorldRegionId,
            ownerId: _gp1,
            townTileKey: _nwTileTown,
          ),
        ],
        owUnits: [_idleBuilder('b1')],
        resourceByTileKey: const {_nwTileTown: 'tobacco', _nwTileA: 'tobacco'},
      );
      final orders = planColonialCivilian(
        game: game,
        snapshot: _civilianSnapshot(),
      );
      expect(orders.map((o) => o.targetTileKey), const [_nwTileA]);
    });

    test('already-improved NW tile excluded', () {
      // The `improvementLevel >= 1` gate must drop every tile that is
      // already at improvement level 1+. A regression that emitted
      // `build_improvement` toward an already-improved tile would
      // waste a Builder cycle and could re-trigger work that the
      // resolver rejects (or, worse, double-count toward the
      // turn-150 improvement gate).
      final game = _civilianGame(
        provinces: const [
          Province(id: _nwProv2, regionId: kNewWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [_idleBuilder('b1')],
        resourceByTileKey: const {_nwTileImproved: 'cotton'},
        tileState: const TileMapState(improvementByTile: {_nwTileImproved: 1}),
      );
      expect(
        planColonialCivilian(game: game, snapshot: _civilianSnapshot()),
        isEmpty,
        reason:
            'All eligible NW tiles already at improvementLevel >= 1; '
            'the planner must emit no orders.',
      );
    });

    test('builder count caps emitted orders below tile count', () {
      // `min(builders, tiles)` cap: two eligible NW tiles, one idle
      // Builder -> exactly one order on the lex-first tile key. The
      // surplus tile remains unimproved this turn (acceptable; the
      // next-turn pass will fill another builder slot).
      final game = _civilianGame(
        provinces: const [
          Province(id: _nwProv1, regionId: kNewWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [_idleBuilder('b1')],
        resourceByTileKey: const {_nwTileA: 'tobacco', _nwTileB: 'sugar'},
      );
      final orders = planColonialCivilian(
        game: game,
        snapshot: _civilianSnapshot(),
      );
      expect(orders.length, 1);
      expect(orders.single.unitId, 'b1');
      expect(orders.single.targetTileKey, _nwTileA);
      expect(orders.single.target, kWorkTargetBuildImprovement);
    });

    test('tile count caps emitted orders below builder count', () {
      // Reverse cap: two idle Builders, one NW tile -> exactly one
      // order bound to the lex-first builder id. The surplus builder
      // remains idle (no fabricated order, no duplicate targeting).
      final game = _civilianGame(
        provinces: const [
          Province(id: _nwProv1, regionId: kNewWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [_idleBuilder('b1'), _idleBuilder('b2')],
        resourceByTileKey: const {_nwTileA: 'tobacco'},
      );
      final orders = planColonialCivilian(
        game: game,
        snapshot: _civilianSnapshot(),
      );
      expect(orders.length, 1);
      expect(orders.single.unitId, 'b1');
      expect(orders.single.targetTileKey, _nwTileA);
    });

    test('multiple eligible NW tiles tie-break ascending by tile key', () {
      // All eligible tiles share the uniform NW-owned score in the
      // current implementation, so ties fall back to lex tile-key
      // sort. Two builders, three tiles spanning two provinces ->
      // ascending lex order across the union is
      // `newWorld|p_delta|3|3`, `newWorld|p_gamma|1|1`,
      // `newWorld|p_gamma|2|2`. With two idle builders sorted
      // ascending by id (`b1`, `b2`), the pairing is
      // `b1 -> nwTileC` and `b2 -> nwTileA`; the third tile is
      // unbound (builder cap). Builder input order is intentionally
      // shuffled (`b2` first) so a regression that dropped the
      // builder sort would surface as the wrong unit-to-tile pairing.
      final game = _civilianGame(
        provinces: const [
          Province(id: _nwProv1, regionId: kNewWorldRegionId, ownerId: _gp1),
          Province(id: _nwProv2, regionId: kNewWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [_idleBuilder('b2'), _idleBuilder('b1')],
        resourceByTileKey: const {
          _nwTileC: 'sugar',
          _nwTileB: 'tobacco',
          _nwTileA: 'tobacco',
        },
      );
      final orders = planColonialCivilian(
        game: game,
        snapshot: _civilianSnapshot(),
      );
      expect(orders.length, 2);
      expect(orders[0].unitId, 'b1');
      expect(orders[0].targetTileKey, _nwTileC);
      expect(orders[1].unitId, 'b2');
      expect(orders[1].targetTileKey, _nwTileA);
      expect(
        orders.every((o) => o.target == kWorkTargetBuildImprovement),
        isTrue,
        reason: 'Every emitted order must target build_improvement.',
      );
    });

    test('working builders and non-Builder units excluded', () {
      // Only `status == idle` Builder units count. Working Builders
      // and idle non-Builder civilians (e.g. Merchant) must be
      // skipped. With no idle Builder present the planner returns
      // empty even when an eligible NW tile exists.
      final game = _civilianGame(
        provinces: const [
          Province(id: _nwProv1, regionId: kNewWorldRegionId, ownerId: _gp1),
        ],
        nwUnits: [
          Unit(
            id: 'b_busy',
            type: kUnitTypeBuilder,
            ownerId: _gp1,
            locationProvinceId: _nwProv1,
            tileKey: '$_nwProv1|7|7',
            status: UnitStatus.working,
          ),
          Unit(
            id: 'merchant1',
            type: kUnitTypeMerchant,
            ownerId: _gp1,
            locationProvinceId: _nwProv1,
            tileKey: '$_nwProv1|6|6',
          ),
        ],
        owUnits: const [],
        resourceByTileKey: const {_nwTileA: 'tobacco'},
      );
      expect(
        planColonialCivilian(game: game, snapshot: _civilianSnapshot()),
        isEmpty,
        reason:
            'Working builders + non-Builder civilians are filtered out; '
            'with no idle Builder present the planner returns empty.',
      );
    });

    test('OW Builder is still assigned to an eligible NW tile', () {
      // The builder roster does not filter by current region: a
      // Builder located in the Old World can still receive a NW
      // improvement directive, with the orchestrator and resolver
      // handling movement / staging on subsequent turns. This pins
      // the "any idle Builder" contract from the function docstring
      // and prevents a regression that adds an implicit region gate
      // on the builder side.
      final game = _civilianGame(
        provinces: const [
          Province(id: _nwProv1, regionId: kNewWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [_idleBuilder('b_ow')],
        resourceByTileKey: const {_nwTileA: 'tobacco'},
      );
      final orders = planColonialCivilian(
        game: game,
        snapshot: _civilianSnapshot(),
      );
      expect(orders.length, 1);
      expect(orders.single.unitId, 'b_ow');
      expect(orders.single.targetTileKey, _nwTileA);
    });

    test('determinism: identical inputs yield identical orders', () {
      // Pins Must-have #7 (determinism) at the in-module level. The
      // mixed-input fixture exercises NW ownership filter, OW
      // suppression, town exclusion, improvement-level filter,
      // builder-status filter, builder sort, and the min cap in one
      // pass. Two calls must produce the same list.
      final game = _civilianGame(
        provinces: const [
          Province(id: _owProv1, regionId: kOldWorldRegionId, ownerId: _gp1),
          Province(
            id: _nwProv1,
            regionId: kNewWorldRegionId,
            ownerId: _gp1,
            townTileKey: _nwTileTown,
          ),
          Province(id: _nwProv2, regionId: kNewWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [_idleBuilder('b2'), _idleBuilder('b1')],
        nwUnits: [_idleBuilder('b3', regionId: kNewWorldRegionId)],
        resourceByTileKey: const {
          _owTileA: 'grain',
          _nwTileTown: 'tobacco',
          _nwTileA: 'tobacco',
          _nwTileB: 'sugar',
          _nwTileImproved: 'cotton',
        },
        tileState: const TileMapState(improvementByTile: {_nwTileImproved: 1}),
      );
      final first = planColonialCivilian(
        game: game,
        snapshot: _civilianSnapshot(),
      );
      final second = planColonialCivilian(
        game: game,
        snapshot: _civilianSnapshot(),
      );
      expect(
        first.map((o) => '${o.unitId}->${o.targetTileKey}').toList(),
        const ['b1->newWorld|p_gamma|1|1', 'b2->newWorld|p_gamma|2|2'],
        reason:
            'OW tile (`grain`) suppressed; NW town tile excluded; '
            'already-improved NW tile filtered; remaining eligible NW '
            'tiles (`newWorld|p_gamma|1|1`, `newWorld|p_gamma|2|2`) '
            'paired with the two lex-first Builders (`b1`, `b2`). The '
            'third builder `b3` has no eligible tile and is unbound.',
      );
      expect(second, first);
    });
  });
}
