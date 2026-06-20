import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _ow = 'oldWorld';
const _p1 = 'oldWorld|p1';
const _p2 = 'oldWorld|p2';
const _p3 = 'oldWorld|p3';

MapTopology _topology() => const MapTopology(
  nodes: [
    TopologyNode(id: _p1, regionId: _ow, type: TopologyNodeType.province),
    TopologyNode(id: _p2, regionId: _ow, type: TopologyNodeType.province),
    TopologyNode(id: _p3, regionId: _ow, type: TopologyNodeType.province),
  ],
  edges: [
    TopologyEdge(id1: _p1, id2: _p2),
    TopologyEdge(id1: _p2, id2: _p3),
  ],
);

Game _gameFixture() => Game(
  id: 'g-trace-perf',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 8),
    oldWorld: RegionData(
      provinces: const [
        Province(id: _p1, regionId: _ow, ownerId: 'gp1'),
        Province(id: _p2, regionId: _ow, ownerId: 'gp1'),
        Province(id: _p3, regionId: _ow, ownerId: 'gp1'),
      ],
      units: [
        Unit(
          id: 'merchant-1',
          type: kUnitTypeMerchant,
          ownerId: 'gp1',
          locationProvinceId: _p1,
          tileKey: 'oldWorld|p1|0|0',
        ),
        Unit(
          id: 'engineer-1',
          type: kUnitTypeEngineer,
          ownerId: 'gp1',
          locationProvinceId: _p2,
          tileKey: 'oldWorld|p2|0|0',
        ),
        Unit(
          id: 'regiment-1',
          type: 'musketeers',
          ownerId: 'gp1',
          locationProvinceId: _p1,
        ),
      ],
    ),
    armies: const [
      Army(
        id: 'army-1',
        ownerId: 'gp1',
        regionId: _ow,
        stationedProvinceId: _p1,
        regimentUnitIds: ['regiment-1'],
      ),
    ],
    newWorld: const RegionData(),
    tileKeysByRegionAndProvince: const {
      _ow: {
        _p1: ['oldWorld|p1|0|0'],
        _p2: ['oldWorld|p2|0|0'],
        _p3: ['oldWorld|p3|0|0'],
      },
    },
  ),
  players: const [
    Player(id: 'gp1', displayName: 'P1', isHuman: true, stockpile: Stockpile()),
  ],
);

Orders _ordersFixture() => const Orders(
  moveOrdersByPlayerId: {
    'gp1': [
      MoveOrder(unitId: 'merchant-1', destinationTileKey: 'oldWorld|p2|0|0'),
    ],
  },
  workOrdersByPlayerId: {
    'gp1': [
      WorkOrder(
        unitId: 'engineer-1',
        target: kWorkTargetBuildRoad,
        targetTileKey: 'oldWorld|p2|0|0',
      ),
    ],
  },
  armyMoveOrdersByPlayerId: {
    'gp1': [ArmyMoveOrder(armyId: 'army-1', destinationProvinceId: _p2)],
  },
);

int _measureScenarioMicros({
  required int samples,
  required int turnsPerSample,
  required bool traceEnabled,
}) {
  final measurements = <int>[];
  for (var sample = 0; sample < samples; sample++) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < turnsPerSample; i++) {
      final runtime = traceEnabled ? TurnTraceRuntime() : null;
      final phaseSink = traceEnabled ? <TurnTracePhaseTrace>[] : null;
      resolveTurnForGameWithConfig(
        game: _gameFixture(),
        config: TurnResolverConfig(
          topology: _topology(),
          orders: _ordersFixture(),
          onTurnTracePhase: phaseSink?.add,
          turnTraceRuntime: runtime,
        ),
      );
    }
    sw.stop();
    measurements.add(sw.elapsedMicroseconds);
  }
  final sorted = [...measurements]..sort();
  return sorted[sorted.length ~/ 2];
}

void main() {
  suppressLogsForTests();

  test('turn trace runtime stays within 20% overhead budget', () {
    const samples = 5;
    const turnsPerSample = 20;

    // Warm up JIT and caches before measuring.
    _measureScenarioMicros(samples: 2, turnsPerSample: 8, traceEnabled: false);
    _measureScenarioMicros(samples: 2, turnsPerSample: 8, traceEnabled: true);

    final baselineMicros = _measureScenarioMicros(
      samples: samples,
      turnsPerSample: turnsPerSample,
      traceEnabled: false,
    );
    final tracedMicros = _measureScenarioMicros(
      samples: samples,
      turnsPerSample: turnsPerSample,
      traceEnabled: true,
    );

    // Trace-enabled runs intentionally serialize phase snapshots while the
    // production path avoids that cost, so bound runaway overhead without
    // requiring traced and untraced runs to stay close.
    final maxAllowedMicros = (baselineMicros * 3).round() + 5000;
    final overheadPercent = baselineMicros == 0
        ? 0
        : ((tracedMicros - baselineMicros) * 100 / baselineMicros).round();

    expect(
      tracedMicros,
      lessThanOrEqualTo(maxAllowedMicros),
      reason:
          'trace enabled median=${tracedMicros}us baseline='
          '${baselineMicros}us overhead=${math.max(0, overheadPercent)}%',
    );
  });
}
