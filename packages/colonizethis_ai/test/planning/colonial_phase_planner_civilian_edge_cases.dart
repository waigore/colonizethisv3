// Case bodies for `colonial_phase_planner_civilian_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

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

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';

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

Unit _idleBuilder(String id, {String regionId = kOldWorldRegionId}) {
  final provinceId = regionId == kOldWorldRegionId ? _owProv1 : _nwProv1;
  return Unit(
    id: id,
    type: kUnitTypeBuilder,
    ownerId: kColonialPhaseGp1,
    locationProvinceId: provinceId,
    tileKey: '$provinceId|9|9',
  );
}


void registerColonialPhasePlannerCivilianEdgeCases() {
  group('planColonialCivilian', () {
    test('OW Builder is still assigned to an eligible NW tile', () {
      // The builder roster does not filter by current region: a
      // Builder located in the Old World can still receive a NW
      // improvement directive, with the orchestrator and resolver
      // handling movement / staging on subsequent turns. This pins
      // the "any idle Builder" contract from the function docstring
      // and prevents a regression that adds an implicit region gate
      // on the builder side.
      final game = buildColonialCivilianGame(
        provinces: const [
          Province(
            id: _nwProv1,
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
        ],
        owUnits: [_idleBuilder('b_ow')],
        resourceByTileKey: const {_nwTileA: 'tobacco'},
      );
      final orders = planColonialCivilian(
        game: game,
        snapshot: buildColonialCivilianSnapshot(),
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
      final game = buildColonialCivilianGame(
        provinces: const [
          Province(
            id: _owProv1,
            regionId: kOldWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
          Province(
            id: _nwProv1,
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp1,
            townTileKey: _nwTileTown,
          ),
          Province(
            id: _nwProv2,
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
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
        snapshot: buildColonialCivilianSnapshot(),
      );
      final second = planColonialCivilian(
        game: game,
        snapshot: buildColonialCivilianSnapshot(),
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
