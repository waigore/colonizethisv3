import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eNavalPanelSnapshot;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show homeFleetIdFor, regionIdForSeaZone;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// True when [data] reads like the naval-panel location row for a fleet in
/// the New World (for example `New World — Outer Sea`).
///
/// `naval_tree_builder.dart` joins region and location with an **em dash**
/// (`—`), but earlier CI dumps and Material text scaling can normalize the
/// glyph to an **en dash** (`–`) or a plain **hyphen-minus** (`-`). The
/// helper accepts all three so fleet-reach detection
/// ([e2eNavalPanelShowsNonHomeFleetInNewWorld]) is not coupled
/// to one specific Unicode glyph.
///
/// Lives in a dedicated file (alongside the snapshot-driven fleet-reach
/// predicates that consume it) so the parent `e2e_test_shared.dart` stays
/// within the repo-lint `dart_file_non_comment_line_size` budget
/// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines). The barrel
/// re-exports this entrypoint so consumers depend on `e2e_test_shared.dart`
/// (or the AC1 `e2e_helpers.dart` barrel) only. Refs GitHub #2336 AC1 /
/// AC2 / Bottleneck 6.
///
/// Contract (Refs GitHub #2336):
/// - `null` and empty string -> `false` (nothing to inspect).
/// - String must begin with `"New World"` after trimming leading whitespace
///   (`trimLeft`); trailing whitespace is preserved so callers can spot
///   suspicious tail content in their own assertions.
/// - The character(s) immediately after `"New World"` must reduce, via a
///   second `trimLeft`, to one of `'—'`, `'–'`, or `'-'`. Anything else
///   (alphanumerics, a colon, or no separator at all) -> `false`.
bool e2eTextLooksLikeNewWorldLocationLine(String? data) {
  if (data == null) {
    return false;
  }
  final trimmed = data.trimLeft();
  const prefix = 'New World';
  if (!trimmed.startsWith(prefix)) {
    return false;
  }
  final after = trimmed.substring(prefix.length);
  if (after.isEmpty) {
    return false;
  }
  final rest = after.trimLeft();
  return rest.startsWith('—') || rest.startsWith('–') || rest.startsWith('-');
}

/// Widget-only: true when a **non-home** fleet row under [kCtE2ENavalPanelRootKey]
/// shows a New World location subtitle (`New World — …` per
/// `naval_tree_builder.dart`).
///
/// Lifted from the formerly private `_navalPanelShowsNonHomeFleetInNewWorld` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2). Used as the UI fallback in
/// [e2eHarnessDetectsNonHomeFleetInNewWorld] when [ctE2eNavalPanelSnapshot] is
/// null (snapshot plumbing unavailable). A silent rename / fail-open here would
/// stall fleet-reach loops at `_kMaxNextTurnTapsForNwFleetReach (35) × ~5 s`
/// (`SPEC/program/e2e-integration-tests.md` § Determinism, #2336 Bottleneck 4).
///
/// Contract:
/// - Returns `false` when the naval panel root key is absent.
/// - Iterates [ExpansionTile] descendants in stable tree order; skips tiles
///   without a `Text` whose `data` starts with `'Fleet '`.
/// - Returns `true` on the first tile that also has a descendant `Text` matching
///   [e2eTextLooksLikeNewWorldLocationLine].
bool e2eNavalPanelShowsNonHomeFleetInNewWorld(WidgetTester tester) {
  final naval = find.byKey(kCtE2ENavalPanelRootKey);
  if (naval.evaluate().isEmpty) {
    return false;
  }
  final tiles = find.descendant(
    of: naval,
    matching: find.byType(ExpansionTile),
  );
  final n = tiles.evaluate().length;
  for (var i = 0; i < n; i++) {
    final sub = tiles.at(i);
    final fleetTitle = find.descendant(
      of: sub,
      matching: find.byWidgetPredicate(
        (w) => w is Text && (w.data?.startsWith('Fleet ') ?? false),
      ),
    );
    if (fleetTitle.evaluate().isEmpty) {
      continue;
    }
    final loc = find.descendant(
      of: sub,
      matching: find.byWidgetPredicate(
        (w) => w is Text && e2eTextLooksLikeNewWorldLocationLine(w.data),
      ),
    );
    if (loc.evaluate().isNotEmpty) {
      return true;
    }
  }
  return false;
}

/// True when [snap] reflects a **non-home human** fleet whose region is
/// `newWorld` — either directly via `Fleet.regionId == 'newWorld'`, or
/// indirectly because the fleet's `seaZoneId` resolves to `newWorld`
/// through `regionIdForSeaZone(snap.topology, …)`.
///
/// Lifted from the formerly private
/// `_nonHomeHumanFleetInNewWorldFromCtSnapshot` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2). The fleet-reach loop short-circuit
/// ([e2eFleetReachDoneFromCtSnapshotOnly],
/// [e2eHarnessDetectsNonHomeFleetInNewWorld])
/// and the bundled-explore readiness loop depend on this predicate to
/// terminate within the 35-turn cap when [ctE2eNavalPanelSnapshot] reports
/// arrival — a silent rename / fail-open here would stall the suite at
/// `_kMaxNextTurnTapsForNwFleetReach × ~5 s` (`SPEC/program/e2e-integration-tests.md`
/// § Determinism, #2336 Bottleneck 4).
///
/// Contract:
///
/// - Returns `false` when [snap] is `null` (no snapshot plumbing this turn).
/// - Iterates `snap.game.worldState.fleets` in stable list order; for each
///   fleet skips when `f.ownerId != snap.humanPlayerId`.
/// - Skips the human's home fleet (`homeFleetIdFor(snap.humanPlayerId)`)
///   so that an opening home-fleet-only state never short-circuits the
///   loop on turn 0.
/// - Returns `true` when the first surviving fleet has `regionId ==
///   'newWorld'`.
/// - Otherwise consults `regionIdForSeaZone(snap.topology, sea)` and
///   returns `true` when the seaboard resolves to `newWorld`. A `null`
///   `seaZoneId` (in-port) or a sea zone the topology cannot resolve
///   keeps iterating.
/// - Returns `false` only after every fleet has been considered.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin
/// in `app/test/e2e_non_home_human_fleet_in_new_world_from_ct_snapshot_test.dart`
/// carries the behavioural contract.
bool e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
  CtE2eNavalPanelSnapshot? snap,
) {
  if (snap == null) {
    return false;
  }
  final human = snap.humanPlayerId;
  final homeId = homeFleetIdFor(human);
  for (final f in snap.game.worldState.fleets) {
    if (f.ownerId != human) continue;
    if (f.id == homeId) continue;
    if (f.regionId == 'newWorld') return true;
    final sea = f.seaZoneId;
    if (sea != null && regionIdForSeaZone(snap.topology, sea) == 'newWorld') {
      return true;
    }
  }
  return false;
}

/// Snapshot-only fleet-reach loop short-circuit (Refs GitHub #2336
/// Bottleneck 4).
///
/// Returns whether [snap] already reports a **non-home human** fleet in the
/// New World so the fleet-reach turn loop can skip `e2eOpenNavalPanel` and
/// redundant widget-tree probes on subsequent iterations. Semantically
/// identical to [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] but named for
/// the call-site contract in `new_game_fleet_reaches_new_world_e2e_test.dart`.
///
/// - Returns `false` when [snap] is `null` (keep iterating).
/// - Does **not** consult the widget tree; use
///   [e2eHarnessDetectsNonHomeFleetInNewWorld] when a UI fallback is required.
bool e2eFleetReachDoneFromCtSnapshotOnly(CtE2eNavalPanelSnapshot? snap) =>
    e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(snap);

/// Fleet-reach / bundled-explore arrival probe with snapshot-first semantics.
///
/// Lifted from the formerly private `_harnessDetectsNonHomeFleetInNewWorld`
/// in `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2).
///
/// Contract:
///
/// - Returns `true` when [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot]
///   reports arrival for [snap] (including when [snap] is non-null and
///   reports `false` — the widget fallback is **not** consulted in that case).
/// - When [snap] is `null`, falls back to
///   [e2eNavalPanelShowsNonHomeFleetInNewWorld] for environments where CT
///   snapshot plumbing is unavailable.
bool e2eHarnessDetectsNonHomeFleetInNewWorld(
  WidgetTester tester,
  CtE2eNavalPanelSnapshot? snap,
) =>
    e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(snap) ||
    (snap == null && e2eNavalPanelShowsNonHomeFleetInNewWorld(tester));
