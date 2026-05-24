part of 'new_game_fleet_reaches_new_world_e2e_test.dart';

/// `_tapMoveOnFirstNonHomeFleet` was lifted into the public
/// [e2eTapMoveOnFirstNonHomeFleet] (`e2e_test_shared_panels.dart`) so the
/// non-home Move-tap contract is shared and unit-pinned (Refs GitHub
/// #2336 AC1 / AC2). The fleet-reach loop calls the lifted form through
/// the AC1 barrel alias `tapMoveOnFirstNonHomeFleet` (`e2e_helpers.dart`).
/// The widget-test pin in
/// `app/test/e2e_tap_move_on_first_non_home_fleet_test.dart` guards
/// against silent regressions (the integration suite cannot validate this
/// directly today — `app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI). A regression here would
/// stall the fleet-reach loop at
/// `_kMaxNextTurnTapsForNwFleetReach (35) × ~5 s` (Bottleneck 4 in
/// `SPEC/program/e2e-integration-tests.md` § Determinism).

/// Naval-panel location row detection moved to
/// [e2eTextLooksLikeNewWorldLocationLine] (`e2e_test_shared.dart`) so the
/// dash-glyph contract is unit-pinned (Refs GitHub #2336).

/// Non-home human fleet-in-NW detection moved to
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] (`e2e_test_shared.dart`)
/// so the snapshot-driven contract is unit-pinned (Refs GitHub #2336 AC1 /
/// AC2). Call sites pass [ctE2eNavalPanelSnapshot] explicitly.

/// Coastal sea-zone adjacency lookup with prefixed-id fallback moved to
/// [e2eNwCoastalProvincesAdjacentToFleetSea] (`e2e_test_shared.dart`) so the
/// two-tier `provinceIdsAdjacentToSeaZone` contract is unit-pinned and shared
/// across scenarios (Refs GitHub #2336 AC1 / AC2). The combined topology
/// uses prefixed sea node ids (`newWorld|sea5`) while some fleet states
/// still carry the regional local id (`sea5`); the lifted helper tries
/// both so coastal detection matches logic/ship-reveal
/// (`SPEC/program/fog-and-exploration-resolution.md`).

/// Non-home human fleet-in-NW-coastal-sea detection moved to
/// [e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot]
/// (`e2e_test_shared.dart`) so the snapshot-driven coastal contract is
/// unit-pinned (Refs GitHub #2336 AC1 / AC2). Ship reveal only paints
/// coastal land for sea zones with a P–S province edge
/// (`SPEC/program/fog-and-exploration-resolution.md`). Open-ocean NW sea
/// placement satisfies [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] but
/// never yields fogged/visible NW provinces, so bundled Explore stays
/// disabled. Call sites pass [ctE2eNavalPanelSnapshot] explicitly.

/// NW fogged-or-better detection moved to
/// [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot] (`e2e_test_shared.dart`)
/// so the [PlayerView]-driven contract is unit-pinned (Refs GitHub #2336
/// AC1 / AC2). Call sites pass [ctE2eNavalPanelSnapshot] explicitly.

/// Naval-panel widget fallback for fleet-in-NW detection moved to
/// [e2eNavalPanelShowsNonHomeFleetInNewWorld] (`e2e_test_shared.dart`) so the
/// ExpansionTile / location-line contract is unit-pinned (Refs GitHub #2336
/// AC1 / AC2).

/// `_harnessDetectsNonHomeFleetInNewWorld` and `_fleetReachDoneFromCtSnapshotOnly`
/// were lifted into [e2eHarnessDetectsNonHomeFleetInNewWorld] and
/// [e2eFleetReachDoneFromCtSnapshotOnly] (`e2e_test_shared.dart`, Refs #2336
/// AC1 / AC2). Call sites pass [ctE2eNavalPanelSnapshot] explicitly.

/// Post–#1869 bundled-Explore readiness wait was lifted into
/// [e2eAwaitNwCoastalOrVisibleLandForBundledExplore]
/// (`e2e_test_shared_panels.dart`) so the 35-turn readiness loop is shared
/// and unit-pinned (Refs GitHub #2336 AC1 / AC2 / Bottleneck 4). The fleet
/// scenario calls the lifted form through the AC1 barrel alias
/// `awaitNwCoastalOrVisibleLandForBundledExplore` (`e2e_helpers.dart`); the
/// widget-test pin in
/// `app/test/e2e_await_nw_coastal_or_visible_land_for_bundled_explore_test.dart`
/// carries the behavioural contract because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI). A regression here would
/// stall the bundled-Explore retry path at
/// `kE2eDefaultBundledExploreReadinessMaxTurns (35)` × per-turn cost —
/// directly inflating the wall-clock budget #2336 is reducing.

/// `_bundledExploreRejectionDiagnostics` was lifted into the public
/// [e2eBundledExploreRejectionDiagnostics] in `e2e_test_shared.dart`
/// (Refs GitHub #2336 AC1 / AC2). The lifted form takes both
/// [CtE2eNavalPanelSnapshot] and [CtE2eCivilianPanelSnapshot] explicitly
/// rather than reading the global panel snapshots, so the diagnostic
/// surface is deterministic and unit-pinned in
/// `app/test/e2e_bundled_explore_rejection_diagnostics_test.dart`. Call
/// sites compose the global fallback (`x ?? ctE2eNavalPanelSnapshot`)
/// themselves before delegating to the public helper.

/// _exploreAssignEnabledFromCivilianSnapshot was lifted into the public
/// [e2eExploreAssignEnabledFromCivilianSnapshot] in `e2e_test_shared.dart`
/// (Refs GitHub #2336 AC1 / AC2). Call sites consume the public name and
/// pass `ctE2eCivilianPanelSnapshot` explicitly; the integration suite
/// re-exports it through the `e2e_helpers.dart` barrel and pins the
/// contract via
/// `app/test/e2e_explore_assign_enabled_from_civilian_snapshot_test.dart`.

/// `_anyExplorerHasEnabledExploreAssignFleetE2e` was lifted into the public
/// [e2eAnyExplorerHasEnabledExploreAssignFleet] in
/// `e2e_test_shared_panels.dart` (Refs GitHub #2336 AC1 / AC2 / AC5 /
/// Bottleneck 5). The fleet bundled-Explore retry loop calls the lifted
/// form through the AC1 barrel alias `anyExplorerHasEnabledExploreAssignFleet`
/// (`e2e_helpers.dart`). The widget-test pin in
/// `app/test/e2e_any_explorer_has_enabled_explore_assign_fleet_test.dart`
/// guards against silent regressions (the integration suite cannot validate
/// this directly today — `app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI). A regression here would
/// stall the bundled-Explore retry loop on the slow
/// `maxPanelSweepSteps (16) × per-step Assign sweep` path described as
/// Bottleneck 5 in `SPEC/program/e2e-integration-tests.md` § Determinism.

/// Next-turn-tap / dialog-handle / label-advance routine was lifted into
/// [e2eAdvanceOneHumanTurn] (`e2e_test_shared.dart`) so the fleet e2e's
/// only next-turn entrypoint is shared and unit-pinned (Refs GitHub #2336
/// AC1 / AC2). The fleet scenarios call the lifted form through the AC1
/// barrel alias `advanceOneHumanTurn` (`e2e_helpers.dart`); the widget-test
/// pin in `app/test/e2e_advance_one_human_turn_test.dart` carries the
/// behavioural contract.

/// The bundled-Explore "check Explore enabled from civilian panel" inline
/// closure was lifted into [e2eCheckExploreEnabledFromCivilianPanel]
/// (`e2e_test_shared_panels.dart`) so the open-civilian → wait-root →
/// Assign-sweep → close-sheet → perf-timing recipe is shared and
/// unit-pinned (Refs GitHub #2336 AC1 / AC2 / AC5 / Bottleneck 5). The
/// post-bundle Explore scenario calls the lifted form through the AC1
/// barrel alias `checkExploreEnabledFromCivilianPanel`
/// (`e2e_helpers.dart`) inside a bounded `maxBoundedTurnRetries (8)` retry
/// loop. The widget-test pin in
/// `app/test/e2e_check_explore_enabled_from_civilian_panel_test.dart`
/// guards against silent regressions (the integration suite cannot
/// validate this directly today — `app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI). A regression that
/// dropped the `closeBottomSheet` call would stall the retry loop on a
/// stale Assign sheet; one that swapped `bottomSheetCloseTimeout` for the
/// default 30 s would inflate the per-iteration wall clock past the
/// `_kMaxUiResponseWait (5s)` cap #2336 is reducing.

/// The duplicated post-loop "final naval check" block (dismiss-transient
/// → region-tab → conditional `openNavalPanel` → harness probe with
/// scenario-specific fail → `closeBottomSheet`) was lifted into
/// [e2eEnsureNonHomeFleetInNwAfterLoop]
/// (`e2e_test_shared_final_naval_reach_check.dart`) so the
/// post-`fleetReachTurnLoop` reach assertion is shared between both
/// `testWidgets` bodies and unit-pinned (Refs GitHub #2336 AC1 / AC2 /
/// Bottleneck 4). The fleet-reach scenarios call the lifted form
/// through the AC1 barrel alias `ensureNonHomeFleetInNwAfterLoop`
/// (`e2e_helpers.dart`) and compose the scenario-specific fail message
/// via `failureMessageBuilder`. Test 2
/// (`new_game_fleet_explore_enabled_post_bundle`) assigns the returned
/// [E2eFinalNavalReachCheckResult.lastKnownNavalSnapshot] into its
/// pre-existing `lastKnownNavalSnapshot` tracker; test 1 ignores the
/// captured snapshot. The widget-test pin in
/// `app/test/e2e_ensure_non_home_fleet_in_nw_after_loop_test.dart`
/// carries the behavioural contract because the integration suite
/// cannot validate this directly today (`app_e2e_linux` is a no-op
/// per `SPEC/program/e2e-integration-tests.md` § CI). A regression
/// that dropped the conditional `openNavalPanel` would mask a real
/// reach failure as a clean exit; one that swapped the order of
/// `dismissTransientUi` / `e2eTapNewWorldRegionTabIfPresent` would
/// read the harness against the wrong region; one that bypassed the
/// `failureMessageBuilder` would orphan the legacy "Last exception:"
/// suffix on CI failures.
