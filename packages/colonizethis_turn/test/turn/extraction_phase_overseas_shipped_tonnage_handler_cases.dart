// Handler plumbing cases for overseas shipped tonnage (Refs #4740 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

import '../support/extraction_auto_transport_test_fixtures.dart';
import '../support/turn_phase_test_harness.dart';

void registerExtractionOverseasShippedTonnageHandlerCases() {
  group(
    'extractionTurnPhaseHandler — TurnPipelineState plumbing (Refs #2990 B2)',
    () {
      test(
        'handler publishes the recorded tonnage onto '
        'TurnPipelineState.overseasExtractionShippedTonnageByPlayerId',
        () {
          final (:game, :tileMapByRegion) = extractionAutoTransportFixture(
            nwResourceGrid: const [
              [Resource.sugarCane, Resource.sugarCane],
              [Resource.sugarCane, Resource.sugarCane],
            ],
            nwImprovementLevel: 1,
          );
          final topology = crossRegionSeaTopologyForExtractionTests();
          final config = TurnResolverConfig(
            topology: topology,
            orders: const Orders(),
            tileMapByRegion: tileMapByRegion,
          );
          final next = runTurnPhaseHandlerPipeline(
            handler: extractionTurnPhaseHandler,
            game: game,
            config: config,
            turnNumber: 0,
          );

          expect(
            next.overseasExtractionShippedTonnageByPlayerId['pl1'],
            isNotNull,
          );
          expect(
            next.overseasExtractionShippedTonnageByPlayerId['pl1']!,
            greaterThan(0),
          );
        },
      );

      test(
        'handler leaves tonnage map empty when no auto-transport runs '
        '(scripted extraction fast path)',
        () {
          final game = Game(
            id: 'g1',
            players: const [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
            ],
            worldState: const WorldState(
              turnState: TurnState(phase: TurnPhase.extraction, turnNumber: 0),
              oldWorld: RegionData(),
              newWorld: RegionData(),
            ),
          );
          final config = TurnResolverConfig(
            topology: const MapTopology(nodes: [], edges: []),
            orders: const Orders(),
            extractedByPlayerId: <String, Map<CommodityId, int>>{
              'pl1': {CommodityCatalog.grain.id: 10},
            },
          );

          final next = runTurnPhaseHandlerPipeline(
            handler: extractionTurnPhaseHandler,
            game: game,
            config: config,
            turnNumber: 0,
          );

          expect(next.overseasExtractionShippedTonnageByPlayerId, isEmpty);
        },
      );
    },
  );
}
