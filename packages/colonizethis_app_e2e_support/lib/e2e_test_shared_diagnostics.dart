/// Cold-failure diagnostic helpers for ColonizeThis E2E scenarios (GitHub
/// #2336 AC1 / AC2, file-size split).
///
/// Lifted out of `e2e_test_shared.dart` so the parent shared library stays
/// at or below the `repo.dart_file_non_comment_line_size` 1000 non-comment
/// line cap (`SPEC/program/dart-file-non-comment-line-size.md`,
/// `colonizethis-code-review.mdc`). The parent file re-exports this library
/// (`export 'e2e_test_shared_diagnostics.dart';`) so the AC1 barrel
/// (`e2e_helpers.dart`) keeps working without import-site churn — every
/// existing widget-unit pin (e.g.
/// `app/test/e2e_bundled_explore_rejection_diagnostics_test.dart`) still
/// resolves [e2eBundledExploreRejectionDiagnostics] via either
/// `e2e_test_shared.dart` or the public-name barrel.
library;

import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eCivilianPanelSnapshot, CtE2eNavalPanelSnapshot;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        OrderEngine,
        allProvinces,
        buildPlayerView,
        kUnitTypeExplorer,
        kWorkTargetExplore,
        suggestWorkOrders;
import 'package:colonizethis_models/colonizethis_models.dart'
    show MoveOrder, ProvinceId, Unit, WorkOrder;

/// Builds the multi-line bundled-Explore failure diagnostic surfaced when
/// the fleet-reach test cannot enable an Explorer's `Assign Explore` row
/// after the New World bundled-Explore retries exhaust
/// (`new_game_fleet_reaches_new_world_e2e_test.dart` final guard).
///
/// Lifted from the formerly private `_bundledExploreRejectionDiagnostics`
/// in `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs
/// GitHub #2336 AC1 / AC2). The lifted form takes both panel snapshots
/// explicitly instead of reading the mutable `ctE2eNavalPanelSnapshot`
/// and `ctE2eCivilianPanelSnapshot` globals, so the contract is
/// deterministic and unit-testable (matches the precedent set by the
/// other lifted snapshot-driven helpers in this library).
///
/// Contract:
///
/// - Returns the literal string
///   `'No ctE2eNavalPanelSnapshot available for diagnostics.'` when
///   [navalSnapshot] is `null`. The error string text is part of the
///   contract — the caller embeds it directly in a `fail()` message, so a
///   silent rename would erase the canonical fallback diagnostic.
/// - Otherwise builds a `'\n'`-joined list of `diag:`-prefixed lines:
///   - `'diag: player=<playerId>'`
///   - `'diag: civilianSnapshotAvailable=<true|false>'`
///   - When `civilianSnapshot != null`:
///     `'diag: availableWorkTargets=<Map.toString()>'`
///   - `'diag: draftMoveOrders=<list of "unitId->provinceId" or empty list>'`
///     using `Unit.provinceIdFromTileKey` to derive the destination
///     province; `'?'` substitutes when the tile key cannot be resolved.
///   - `'diag: suggestedExplore=<list of "unitId@provinceId" entries>'`
///     filtered to `suggestWorkOrders` output rows where
///     `target == kWorkTargetExplore`.
/// - If the human player view has **zero** Explorer units, appends a
///   single closing line `'diag: no explorer units found in player view.'`
///   and returns immediately (no per-province probe block).
/// - Otherwise sorts explorer units ascending by `unit.id`, and for each
///   explorer:
///   - Emits `'diag: explorer unit=<id> atProvince=<provinceId> tileKey=<tileKey|"(null)">'`.
///   - For every province in `allProvinces(game.worldState)` sorted
///     ascending by `province.id`, computes an `ownerKind`
///     (`'none'`, `'self'`, `'tribe'`, `'minor'`, `'gp'`) and probes the
///     explore + move acceptance via two fresh [OrderEngine] instances
///     against the snapshot's draft orders, emitting one
///     `'diag: province=&lt;id&gt; owner=&lt;id|"(none)"&gt; '`
///     `'ownerKind=&lt;kind&gt; visibleFoggedPlus=&lt;bool&gt; '`
///     `'workAccepted=&lt;bool&gt; workReason=&lt;string|"(none)"&gt; '`
///     `'moveAccepted=&lt;bool&gt; moveReason=&lt;string|"(none)"&gt;'`
///     line per province.
/// - `visibleFoggedPlus` is `true` whenever any tile key in
///   `view.visibilityByTile` whose first two `|`-segments match the
///   province (`regionId|localId`) has a level whose name is not
///   `'unknown'` (i.e. `'fogged'` or `'fullyVisible'`). Tile keys that
///   do not split into exactly four `|`-segments are skipped (mirrors
///   `e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot` parsing).
///
/// The function is **pure** with respect to its inputs: identical
/// `(navalSnapshot, civilianSnapshot)` pairs must yield byte-identical
/// strings (the deterministic explorer + province sort plus the
/// fresh-per-call [OrderEngine] probes ensure this). The
/// per-province loop costs `O(explorerUnits × provinces)` order-engine
/// probes; callers should only invoke this helper from the cold failure
/// path (Refs `colonizethis-turn-resolution-budget.mdc` "Avoid
/// per-candidate debug logs in tight paths").
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin
/// in `app/test/e2e_bundled_explore_rejection_diagnostics_test.dart`
/// carries the behavioural contract.
String e2eBundledExploreRejectionDiagnostics({
  required CtE2eNavalPanelSnapshot? navalSnapshot,
  required CtE2eCivilianPanelSnapshot? civilianSnapshot,
}) {
  if (navalSnapshot == null) {
    return 'No ctE2eNavalPanelSnapshot available for diagnostics.';
  }
  final game = navalSnapshot.game;
  final topology = navalSnapshot.topology;
  final playerId = navalSnapshot.humanPlayerId;
  final orders = navalSnapshot.draftOrders;
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestWorkOrders(view, game, topology, orders);

  bool provinceHasFoggedOrBetter(String provinceFullId) {
    final regionId = ProvinceId.regionIdFrom(provinceFullId);
    final localId = ProvinceId.localIdFrom(provinceFullId);
    for (final e in view.visibilityByTile.entries) {
      final parts = e.key.split('|');
      if (parts.length != 4) {
        continue;
      }
      if (parts[0] != regionId || parts[1] != localId) {
        continue;
      }
      if (e.value.name != 'unknown') {
        return true;
      }
    }
    return false;
  }

  final lines = <String>[
    'diag: player=$playerId',
    'diag: civilianSnapshotAvailable=${civilianSnapshot != null}',
    if (civilianSnapshot != null)
      'diag: availableWorkTargets=${civilianSnapshot.availableWorkTargets}',
    'diag: draftMoveOrders=${orders.moveOrdersByPlayerId[playerId]?.map((o) => "${o.unitId}->${Unit.provinceIdFromTileKey(o.destinationTileKey) ?? "?"}").toList() ?? const []}',
    'diag: suggestedExplore=${suggestions.where((o) => o.target == kWorkTargetExplore).map((o) => "${o.unitId}@${Unit.provinceIdFromTileKey(o.targetTileKey) ?? "?"}").toList()}',
  ];

  final explorerUnits =
      view.ownUnits.where((u) => u.type == kUnitTypeExplorer).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  if (explorerUnits.isEmpty) {
    lines.add('diag: no explorer units found in player view.');
    return lines.join('\n');
  }

  final provinces = allProvinces(game.worldState).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final tribeIds = game.tribes.map((t) => t.id).toSet();
  final minorIds = game.minorNations.map((m) => m.id).toSet();
  for (final unit in explorerUnits) {
    lines.add(
      'diag: explorer unit=${unit.id} atProvince=${unit.locationProvinceId} tileKey=${unit.tileKey ?? "(null)"}',
    );
    for (final prov in provinces) {
      final foggedOrBetter = provinceHasFoggedOrBetter(prov.id);
      final owner = prov.ownerId;
      final ownerKind = owner == null
          ? 'none'
          : owner == playerId
          ? 'self'
          : tribeIds.contains(owner)
          ? 'tribe'
          : minorIds.contains(owner)
          ? 'minor'
          : 'gp';
      final targetTileKey = '${prov.id}|0|0';
      final workRes = OrderEngine(initialOrders: orders)
          .addWorkOrderWithContext(
            game,
            topology,
            playerId,
            WorkOrder(
              unitId: unit.id,
              target: kWorkTargetExplore,
              targetTileKey: targetTileKey,
            ),
          );
      final moveRes = OrderEngine(initialOrders: orders)
          .addMoveOrderWithContext(
            game,
            topology,
            playerId,
            MoveOrder(unitId: unit.id, destinationTileKey: '${prov.id}|0|0'),
          );
      lines.add(
        'diag: province=${prov.id} owner=${prov.ownerId ?? "(none)"} ownerKind=$ownerKind '
        'visibleFoggedPlus=$foggedOrBetter '
        'workAccepted=${workRes.isAccepted} workReason=${workRes.reason ?? "(none)"} '
        'moveAccepted=${moveRes.isAccepted} moveReason=${moveRes.reason ?? "(none)"}',
      );
    }
  }
  return lines.join('\n');
}
