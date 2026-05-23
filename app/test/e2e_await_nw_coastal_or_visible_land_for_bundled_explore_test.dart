/// Pins the widget-tree contract of
/// [e2eAwaitNwCoastalOrVisibleLandForBundledExplore]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// The post-bundle Explore scenario in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper via
/// the AC1 barrel alias `awaitNwCoastalOrVisibleLandForBundledExplore` to
/// bridge `e2eHarnessDetectsNonHomeFleetInNewWorld` (fleet has reached open
/// NW sea) and the strict `anyExplorerHasEnabledExploreAssignFleet` check
/// (Explore is enabled, requiring coastal land visibility per
/// `SPEC/program/fog-and-exploration-resolution.md`). A silent rename or
/// fail-open would either skip the readiness wait — masking a real Explore
/// regression — or stall the loop at
/// `kE2eDefaultBundledExploreReadinessMaxTurns (35) × ~5 s per iteration`,
/// directly inflating the wall-clock cap #2336 is reducing
/// (Bottleneck 4 in `SPEC/program/e2e-integration-tests.md` § Determinism).
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test layer
/// carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 4.
library;

import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyEdge, TopologyNode, TopologyNodeType;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';

const String _human = 'gp1';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const RegionData _emptyRegion = RegionData();
const Orders _emptyOrders = Orders();
const MapTopology _emptyTopology = MapTopology();

Province _nwProvince(String localId) =>
    Province(id: ProvinceId.full('newWorld', localId), regionId: 'newWorld');

Fleet _homeFleet() => Fleet(
  id: 'fleet_$_human',
  ownerId: _human,
  regionId: 'oldWorld',
  inPortAtProvinceId: 'oldWorld|capital',
);

MapTopology _coastalNwTopology({
  required String seaId,
  required List<String> adjacentProvinceIds,
}) => MapTopology(
  nodes: [
    TopologyNode(
      id: seaId,
      regionId: 'newWorld',
      type: TopologyNodeType.seaZone,
    ),
    for (final pid in adjacentProvinceIds)
      TopologyNode(
        id: pid,
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
  ],
  edges: [
    for (final pid in adjacentProvinceIds) TopologyEdge(id1: pid, id2: seaId),
  ],
);

Game _gameWithFleets({
  List<Fleet> fleets = const [],
  RegionData newWorld = _emptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: _orderingTurn,
    oldWorld: _emptyRegion,
    newWorld: newWorld,
    fleets: fleets,
    playerVisibilityByTile: playerVisibilityByTile,
  ),
  players: const [Player(id: _human, displayName: 'You', isHuman: true)],
);

CtE2eNavalPanelSnapshot _snapshot({
  List<Fleet> fleets = const [],
  MapTopology topology = _emptyTopology,
  RegionData newWorld = _emptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => CtE2eNavalPanelSnapshot(
  game: _gameWithFleets(
    fleets: fleets,
    newWorld: newWorld,
    playerVisibilityByTile: playerVisibilityByTile,
  ),
  humanPlayerId: _human,
  topology: topology,
  draftOrders: _emptyOrders,
);

CtE2eNavalPanelSnapshot _coastalArrivalSnapshot() => _snapshot(
  fleets: [
    _homeFleet(),
    Fleet(
      id: 'fleet_human_split',
      ownerId: _human,
      regionId: 'newWorld',
      seaZoneId: 'sea_nw_1',
    ),
  ],
  topology: _coastalNwTopology(
    seaId: 'sea_nw_1',
    adjacentProvinceIds: const ['newWorld|p1'],
  ),
);

CtE2eNavalPanelSnapshot _foggedNwSnapshot() => _snapshot(
  newWorld: RegionData(provinces: [_nwProvince('p1')]),
  playerVisibilityByTile: const {
    _human: {'newWorld|p1|0|0': 'fogged'},
  },
);

Future<void> _pumpEmpty(WidgetTester tester) =>
    tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

void main() {
  suppressLogsForTests();

  setUp(() {
    ctE2eNavalPanelSnapshot = null;
  });

  tearDown(() {
    ctE2eNavalPanelSnapshot = null;
  });

  group('e2eAwaitNwCoastalOrVisibleLandForBundledExplore — defaults', () {
    test(
      'kE2eDefaultBundledExploreReadinessMaxTurns matches the legacy 35-turn cap',
      () {
        expect(
          kE2eDefaultBundledExploreReadinessMaxTurns,
          35,
          reason:
              'Lifted-from constant must match the legacy private '
              '`maxTurns = 35` literal so the bundled-Explore readiness '
              'loop ceiling stays aligned with '
              '`_kMaxNextTurnTapsForNwFleetReach (35)` in '
              '`new_game_fleet_reaches_new_world_e2e_helpers.dart`. A '
              'silent change would either let the loop run longer than '
              'the documented Bottleneck 4 ceiling (#2336) or '
              'short-circuit early and skip the readiness wait.',
        );
      },
    );
  });

  group(
    'e2eAwaitNwCoastalOrVisibleLandForBundledExplore — bounded loop',
    () {
      testWidgets(
        'maxTurns: 0 is a complete no-op — ensureUnderWallClock never invoked',
        (tester) async {
          await _pumpEmpty(tester);
          final l10n = lookupAppLocalizations(const Locale('en'));
          final steps = <String>[];
          await e2eAwaitNwCoastalOrVisibleLandForBundledExplore(
            tester,
            l10n,
            ensureUnderWallClock: steps.add,
            maxTurns: 0,
          );
          expect(
            steps,
            isEmpty,
            reason:
                'A zero-iteration call must not enter the for-body, '
                'must not invoke the wall-clock guard, and must not '
                'attempt to open the naval panel — otherwise callers '
                'cannot pass `maxTurns: 0` as a safe disarm during '
                'tests or stub scenarios.',
          );
        },
      );

      testWidgets(
        'maxTurns honours the caller override (uses the parameter, not the default)',
        (tester) async {
          await _pumpEmpty(tester);
          final l10n = lookupAppLocalizations(const Locale('en'));
          final steps = <String>[];
          // Snapshot satisfies neither predicate; the helper would normally
          // attempt naval-panel work, but with maxTurns: 0 the loop must
          // not enter even when the snapshot is non-null.
          ctE2eNavalPanelSnapshot = _snapshot();
          await e2eAwaitNwCoastalOrVisibleLandForBundledExplore(
            tester,
            l10n,
            ensureUnderWallClock: steps.add,
            maxTurns: 0,
          );
          expect(
            steps,
            isEmpty,
            reason:
                'maxTurns: 0 must short-circuit before the first '
                'iteration even when the snapshot is non-null but '
                'fails both readiness predicates — a regression that '
                'silently used the default 35 here would burn the '
                'full Bottleneck 4 budget in any test that disabled '
                'the loop.',
          );
        },
      );
    },
  );

  group(
    'e2eAwaitNwCoastalOrVisibleLandForBundledExplore — coastal short-circuit',
    () {
      testWidgets(
        'coastal-NW snapshot exits on iteration 0 — single step recorded',
        (tester) async {
          await _pumpEmpty(tester);
          final l10n = lookupAppLocalizations(const Locale('en'));
          ctE2eNavalPanelSnapshot = _coastalArrivalSnapshot();
          final steps = <String>[];
          await e2eAwaitNwCoastalOrVisibleLandForBundledExplore(
            tester,
            l10n,
            ensureUnderWallClock: steps.add,
            maxTurns: kE2eDefaultBundledExploreReadinessMaxTurns,
          );
          expect(
            steps,
            equals(<String>['NW bundled-explore readiness i=0']),
            reason:
                'A snapshot satisfying '
                '`e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot` '
                'at iteration 0 must short-circuit after one '
                '`ensureUnderWallClock` callback and one snapshot probe — '
                'never advancing to the open-naval-panel / move-segment / '
                'next-turn path. A regression that re-opened the naval '
                'sheet anyway would burn ~5 s per turn × 35 turns.',
          );
        },
      );
    },
  );

  group(
    'e2eAwaitNwCoastalOrVisibleLandForBundledExplore — fogged-or-better short-circuit',
    () {
      testWidgets(
        'NW-fogged snapshot exits on iteration 0 — single step recorded',
        (tester) async {
          await _pumpEmpty(tester);
          final l10n = lookupAppLocalizations(const Locale('en'));
          ctE2eNavalPanelSnapshot = _foggedNwSnapshot();
          final steps = <String>[];
          await e2eAwaitNwCoastalOrVisibleLandForBundledExplore(
            tester,
            l10n,
            ensureUnderWallClock: steps.add,
            maxTurns: kE2eDefaultBundledExploreReadinessMaxTurns,
          );
          expect(
            steps,
            equals(<String>['NW bundled-explore readiness i=0']),
            reason:
                'The disjunction with '
                '`e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot` '
                'must short-circuit on the first iteration even when the '
                'coastal predicate is false (no fleets in NW). A '
                'regression that required both predicates to be true '
                'would stall the readiness wait whenever the player '
                'reached NW visibility via warp/scout rather than via '
                'a coastal sea zone.',
          );
        },
      );
    },
  );

  group(
    'e2eAwaitNwCoastalOrVisibleLandForBundledExplore — step label format',
    () {
      testWidgets(
        'step label uses `NW bundled-explore readiness i=<idx>` form',
        (tester) async {
          await _pumpEmpty(tester);
          final l10n = lookupAppLocalizations(const Locale('en'));
          ctE2eNavalPanelSnapshot = _coastalArrivalSnapshot();
          final steps = <String>[];
          await e2eAwaitNwCoastalOrVisibleLandForBundledExplore(
            tester,
            l10n,
            ensureUnderWallClock: steps.add,
            maxTurns: 1,
          );
          expect(
            steps.single,
            matches(RegExp(r'^NW bundled-explore readiness i=\d+$')),
            reason:
                'Wall-clock guards captured for `#2336` debug runs key '
                'on this label prefix to attribute readiness-loop '
                'overshoot to the correct helper. A silent rename '
                'would surface in CI as an opaque `wall_clock_exceeded` '
                'failure with no helper attribution.',
          );
          expect(
            steps.single,
            equals('NW bundled-explore readiness i=0'),
            reason:
                'Iteration index must be 0-based and embedded into the '
                'label so a regression that reset the counter or used '
                '1-based indexing surfaces here, not as a confusing '
                'off-by-one in CI logs.',
          );
        },
      );
    },
  );

  group(
    'e2eAwaitNwCoastalOrVisibleLandForBundledExplore — AC1 barrel forwarding',
    () {
      testWidgets(
        'awaitNwCoastalOrVisibleLandForBundledExplore (barrel alias) '
        'short-circuits identically to the lifted form',
        (tester) async {
          await _pumpEmpty(tester);
          final l10n = lookupAppLocalizations(const Locale('en'));
          ctE2eNavalPanelSnapshot = _coastalArrivalSnapshot();
          final steps = <String>[];
          await awaitNwCoastalOrVisibleLandForBundledExplore(
            tester,
            l10n,
            ensureUnderWallClock: steps.add,
            maxTurns: kE2eDefaultBundledExploreReadinessMaxTurns,
          );
          expect(
            steps,
            equals(<String>['NW bundled-explore readiness i=0']),
            reason:
                'The AC1 barrel wrapper must forward arguments in the '
                'documented order — a regression that swapped '
                '`ensureUnderWallClock` with `maxTurns`, dropped '
                '`l10n`, or accidentally captured a fresh `maxTurns` '
                'default would surface here, not in the slow CI lane.',
          );
        },
      );

      test(
        'awaitNwCoastalOrVisibleLandForBundledExplore is re-exported as a '
        'tear-off (compile-time signature pin)',
        () {
          final Future<void> Function(
            WidgetTester,
            AppLocalizations, {
            required void Function(String step) ensureUnderWallClock,
            int maxTurns,
            Duration maxUiResponseWait,
          })
          ref = awaitNwCoastalOrVisibleLandForBundledExplore;
          expect(
            ref,
            isNotNull,
            reason:
                'The AC1 barrel must continue to export the helper with '
                'the documented signature. A silent removal from the '
                '`show` clause or an arg-order swap on the wrapper '
                'would fail this assignment at compile time.',
          );
        },
      );
    },
  );
}
