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
//     against the canonical `planDevelopPeace` / `planDevelopCivilian`
//     contracts now that the S5 orchestrator wiring is in place.
//   - The fixture explicitly includes tribe-owned NW provinces, an
//     owned NW province with a resource tile, and tribe / minor
//     factions in `atWarWith` — every surface a DEVELOP planner
//     could possibly leak through.

import 'package:colonizethis_ai/src/planning/develop_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/phase_planner_nw_suppression_test_support.dart';

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
      final game = buildDevelopPhaseNwSuppressionGame();
      final snapshot = buildDevelopPhaseNwSuppressionSnapshot();

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
      expect(peace, containsAll(<String>[kNwSuppressionGp2, kNwSuppressionGp3]));

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
          kNwSuppressionGp1,
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
        kDevelopNwSuppressionOwnedNwTileKey,
        kDevelopNwSuppressionOwnedOwTileKey,
      ]);

      // 3. Structural NW-tile rejection pin: even though the
      //    fixture includes tribe-owned and unowned NW tiles with
      //    resource entries, those tile keys must never appear in
      //    the planner-set output. Tests the ownership gate from
      //    the negative side.
      final emittedTileKeys = civilian.map((o) => o.targetTileKey).toSet();
      expect(
        emittedTileKeys.contains(kDevelopNwSuppressionTribeNwTileKey),
        isFalse,
        reason:
            'planDevelopCivilian must not emit improvements toward '
            'tribe-held NW tiles. The tribe-NW tile resource entry '
            'is present in the fixture; rejection must come from '
            'the ownership gate (province.ownerId != playerId).',
      );
      expect(
        emittedTileKeys.contains(kDevelopNwSuppressionUnownedNwTileKey),
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
      final game = buildDevelopPhaseNwSuppressionGame();
      final snapshot = buildDevelopPhaseNwSuppressionSnapshot(
        atWarWith: const [kNwSuppressionTribe1, kNwSuppressionMinor1],
      );

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
              _ownerOfProvinceContainingTile(game, order.targetTileKey) != kNwSuppressionGp1,
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
      final game = buildDevelopPhaseNwSuppressionGame();
      final snapshot = buildDevelopPhaseNwSuppressionSnapshot();
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
      expect(nwOrders.single.targetTileKey, kDevelopNwSuppressionOwnedNwTileKey);
    });

    test('determinism across the planner set (Must-have #7): same '
        'NW-rich fixture -> identical plan outputs across two runs', () {
      // Pins the per-function determinism contract at the
      // planner-set level: both planners must remain pure functions
      // even when called together in the orchestrator dispatch
      // order. A regression that cached state across calls would
      // surface here.
      final game = buildDevelopPhaseNwSuppressionGame();
      final snapshot = buildDevelopPhaseNwSuppressionSnapshot();

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
