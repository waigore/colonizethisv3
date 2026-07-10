// Table-driven order suggestion pass context scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_pass_context.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import '../scenario_runner.dart';
import 'order_suggestion_pass_context_fixtures.dart';

void ospcRunIndexSkipsEmptyTargets() {
  final indexed = indexExistingTargetsByEntityId(
    const [
      NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaA'),
      NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: ''),
    ],
    (o) => o.fleetId,
    (o) => o.destinationSeaZoneId ?? '',
    skipEmptyTargets: true,
  );
  expect(indexed['f1'], {'seaA'});
}

void ospcRunEmitCollectsInOrder() {
  final into = <NavalMoveOrder>[];
  emitAcceptedCandidates<NavalMoveOrder>(
    candidates: const [
      NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaB'),
      NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaA'),
      NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaC'),
    ],
    accept: (o) => o.destinationSeaZoneId != 'seaC',
    into: into,
  );
  expect(
    into.map((o) => o.destinationSeaZoneId).toList(),
    ['seaB', 'seaA'],
    reason: 'preserves candidate order and performs no sorting',
  );
}

void ospcRunEmitSkipsAlreadyTargeted() {
  final into = <NavalMoveOrder>[];
  emitAcceptedCandidates<NavalMoveOrder>(
    candidates: const [
      NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaA'),
      NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaB'),
      NavalMoveOrder(fleetId: 'f2', destinationSeaZoneId: 'seaA'),
    ],
    accept: (_) => true,
    into: into,
    existingByEntity: {
      'f1': {'seaA'},
    },
    entityId: (o) => o.fleetId,
    dedupKey: (o) => o.destinationSeaZoneId ?? '',
  );
  expect(into.map((o) => '${o.fleetId}:${o.destinationSeaZoneId}').toList(), [
    'f1:seaB',
    'f2:seaA',
  ]);
}

void ospcRunEmitProbesWithoutDedupArgs() {
  final into = <NavalMoveOrder>[];
  emitAcceptedCandidates<NavalMoveOrder>(
    candidates: const [
      NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaA'),
      NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaA'),
    ],
    accept: (_) => true,
    into: into,
    existingByEntity: {
      'f1': {'seaA'},
    },
  );
  expect(into.length, 2);
}

void ospcRunCappedProbeLoopRespectsCaps() {
  final accepted = <int>[];
  final probes = List.generate(10, (i) => i);
  runCappedSuggestionProbeLoop<int>(
    candidates: probes,
    shouldSkip: (n) => n.isEven,
    probe: (n) => n % 3 == 1,
    onAccepted: accepted.add,
    maxAccepted: 2,
    maxProbes: 4,
  );
  expect(accepted, [1, 7]);
}

void ospcRunOwnedProvinceIdsFromView() {
  final view = buildPlayerView(
    orderSuggestionPassContextOwnedProvincesGame(),
    orderSuggestionPassContextTopology,
    orderSuggestionPassContextGp1Id,
  );
  expect(ownedProvinceIdsFromView(view, orderSuggestionPassContextGp1Id), {
    ProvinceId.full(kOldWorldRegionId, 'p1'),
  });
}

/// Scenarios for indexExistingTargetsByEntityId.
List<RunnableScenario> indexExistingTargetsByEntityIdScenarios() => const [
  RunnableScenario(
    label: 'indexExistingTargetsByEntityId skips empty targets when requested',
    run: ospcRunIndexSkipsEmptyTargets,
    refs: '#3500',
  ),
];

/// Scenarios for emitAcceptedCandidates.
List<RunnableScenario> emitAcceptedCandidatesScenarios() => const [
  RunnableScenario(
    label: 'emitAcceptedCandidates collects accepted in iteration order',
    run: ospcRunEmitCollectsInOrder,
    refs: '#3500',
  ),
  RunnableScenario(
    label: 'emitAcceptedCandidates skips candidates already targeted',
    run: ospcRunEmitSkipsAlreadyTargeted,
    refs: '#3500',
  ),
  RunnableScenario(
    label: 'emitAcceptedCandidates probes every candidate without dedup args',
    run: ospcRunEmitProbesWithoutDedupArgs,
    refs: '#3500',
  ),
];

/// Scenarios for runCappedSuggestionProbeLoop.
List<RunnableScenario> runCappedSuggestionProbeLoopScenarios() => const [
  RunnableScenario(
    label: 'runCappedSuggestionProbeLoop respects acceptance and probe caps',
    run: ospcRunCappedProbeLoopRespectsCaps,
    refs: '#3500',
  ),
];

/// Scenarios for ownedProvinceIdsFromView.
List<RunnableScenario> ownedProvinceIdsFromViewScenarios() => const [
  RunnableScenario(
    label: 'ownedProvinceIdsFromView returns full province ids for owner',
    run: ospcRunOwnedProvinceIdsFromView,
    refs: '#3500',
  ),
];
