/// Pins the snapshot-driven bundled-Explore diagnostic surface of
/// [e2eBundledExploreRejectionDiagnostics]
/// (`app/integration_test/e2e_test_shared.dart`).
///
/// The fleet-reach test's final guard
/// (`new_game_fleet_reaches_new_world_e2e_test.dart` line ~408) calls this
/// helper to build the multi-line diagnostic embedded in the bundled-Explore
/// failure `fail()` message. The fail-message text is part of the
/// observable contract (it is grep-able from CI logs by the
/// `'No ctE2eNavalPanelSnapshot available for diagnostics.'` and `'diag:'`
/// prefixes) so a silent rename, line-order swap, or accidental
/// fail-open ("always emit the empty string") here would either:
///
///   - Hide the failing fleet-reach `availableWorkTargets` / `suggestedExplore`
///     details under a generic `fail()` message and erase the per-province
///     `workReason` / `moveReason` lines reviewers grep for when triaging
///     post-bundle #1869 regressions; or
///   - Make the deterministic per-explorer + per-province ordering
///     `(ascending by unit.id, ascending by province.id)` drift, masking
///     non-deterministic AI / order-engine state in CI runs where the
///     diagnostic is the only post-mortem record.
///
/// The function takes both [CtE2eNavalPanelSnapshot] and
/// [CtE2eCivilianPanelSnapshot] explicitly rather than reading the global
/// `ctE2eNavalPanelSnapshot` / `ctE2eCivilianPanelSnapshot` so the
/// diagnostic is deterministic and unit-testable (matches the lifted
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] /
/// [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot] /
/// [e2eExploreAssignEnabledFromCivilianSnapshot] precedents).
///
/// The integration suite cannot validate this directly today
/// (the `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test
/// layer carries the behavioural pin (Refs GitHub #2336 AC1 / AC2).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetExplore, kWorkTargetProspect;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';


part 'support/bundled_explore_fallback_part.dart';
part 'support/bundled_explore_header_part.dart';
part 'support/bundled_explore_no_explorers_part.dart';
part 'support/bundled_explore_probe_part.dart';
part 'support/bundled_explore_determinism_part.dart';

const String _human = 'gp1';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const MapTopology _emptyTopology = MapTopology();

const Orders _emptyOrders = Orders();

const RegionData _emptyRegion = RegionData();

Unit _explorer({
  required String id,
  required String provinceId,
  String? tileKey,
}) => Unit(
  id: id,
  type: kUnitTypeExplorer,
  ownerId: _human,
  locationProvinceId: provinceId,
  tileKey: tileKey,
);

WorldState _world({
  RegionData oldWorld = _emptyRegion,
  RegionData newWorld = _emptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => WorldState(
  turnState: _orderingTurn,
  oldWorld: oldWorld,
  newWorld: newWorld,
  playerVisibilityByTile: playerVisibilityByTile,
);

Game _game({
  RegionData oldWorld = _emptyRegion,
  RegionData newWorld = _emptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => Game(
  id: 'g1',
  worldState: _world(
    oldWorld: oldWorld,
    newWorld: newWorld,
    playerVisibilityByTile: playerVisibilityByTile,
  ),
  players: const [Player(id: _human, displayName: 'You', isHuman: true)],
);

CtE2eNavalPanelSnapshot _navalSnapshot({
  RegionData oldWorld = _emptyRegion,
  RegionData newWorld = _emptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
  Orders draftOrders = _emptyOrders,
}) => CtE2eNavalPanelSnapshot(
  game: _game(
    oldWorld: oldWorld,
    newWorld: newWorld,
    playerVisibilityByTile: playerVisibilityByTile,
  ),
  humanPlayerId: _human,
  topology: _emptyTopology,
  draftOrders: draftOrders,
);

CtE2eCivilianPanelSnapshot _civilianSnapshot({
  Map<String, List<String>> availableWorkTargets = const {},
}) => CtE2eCivilianPanelSnapshot(
  game: _game(),
  humanPlayerId: _human,
  currentOrders: _emptyOrders,
  availableWorkTargets: availableWorkTargets,
);


void main() {
  suppressLogsForTests();
  registerBundledExploreFallbackGroup();
  registerBundledExploreHeaderGroup();
  registerBundledExploreNoExplorersGroup();
  registerBundledExploreProbeGroup();
  registerBundledExploreDeterminismGroup();
}
