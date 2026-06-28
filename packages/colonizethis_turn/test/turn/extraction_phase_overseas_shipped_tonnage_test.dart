import 'package:colonizethis_turn/src/turn/phases/extraction_phase.dart';
import 'package:colonizethis_turn/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_turn/src/turn/turn_resolver_config.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import '../extraction_auto_transport_test_fixtures.dart';

/// Producer side of the cargo-released-by-extraction signal (Refs #2990
/// B2). Asserts that:
///
/// * `runExtractionPhase(..., overseasShippedTonnageOut: out)` records the
///   per-player post-cargo-cap, pre-interception allocation into `out`
///   when the auto-transport path runs.
/// * `extractionTurnPhaseHandler` plumbs the recorded tonnage onto
///   [TurnPipelineState.overseasExtractionShippedTonnageByPlayerId].
/// * The scripted-extraction fast path (non-empty
///   `config.extractedByPlayerId`) does *not* populate tonnage (no
///   auto-transport is run, so no holds are committed).
///
/// The consumer side (world-market phase subtracting tonnage from cargo
/// capacity) is covered in `world_market_phase_extraction_cargo_test.dart`.
void main() {
  group(
    'runExtractionPhase — overseasShippedTonnageOut (Refs #2990 B2)',
    () {
      test(
        'auto-transport path records per-player tonnage matching the sum '
        'of allocated overseas commodities',
        () {
          final (:game, :tileMapByRegion) = extractionAutoTransportFixture(
            nwResourceGrid: const [
              [Resource.sugarCane, Resource.sugarCane],
              [Resource.sugarCane, Resource.sugarCane],
            ],
            nwImprovementLevel: 1,
          );
          final topology = crossRegionSeaTopologyForExtractionTests();
          final priorStockpile = game.players
              .firstWhere((p) => p.id == 'pl1')
              .stockpile;

          final shipped = <String, int>{};
          final next = runExtractionPhase(
            game,
            topology,
            tileMapByRegion,
            <String, Map<CommodityId, int>>{},
            overseasShippedTonnageOut: shipped,
          );

          final nextPlayer = next.players.firstWhere((p) => p.id == 'pl1');
          // Use the sugarCane stockpile delta as a reliable lower bound:
          // anything in the post-extraction stockpile beyond the prior
          // amount and beyond the land-extracted amount came from overseas
          // auto-transport and therefore must have been shipped.
          final sugarBefore = priorStockpile.quantityOf(
            CommodityCatalog.sugarCane.id,
          );
          final sugarAfter = nextPlayer.stockpile.quantityOf(
            CommodityCatalog.sugarCane.id,
          );
          final sugarOverseas = sugarAfter - sugarBefore;
          expect(
            sugarOverseas,
            greaterThan(0),
            reason:
                'fixture configures NW sugarCane overseas extraction; the '
                'test depends on at least one unit arriving',
          );

          expect(
            shipped['pl1'],
            isNotNull,
            reason: 'pl1 has an overseas allocation → tonnage must be '
                'recorded under the player id',
          );
          // No interception in this fixture (no enemies, no patrols), so
          // the recorded tonnage equals the delivered amount on the
          // stockpile.
          expect(shipped['pl1'], sugarOverseas);
        },
      );

      test(
        'scripted extractedByPlayerId fast path does NOT record tonnage '
        '(auto-transport is bypassed)',
        () {
          final game = Game(
            id: 'g1',
            players: const [
              Player(
                id: 'pl1',
                displayName: 'Spain',
                isHuman: true,
              ),
            ],
            worldState: const WorldState(
              turnState: TurnState(phase: TurnPhase.extraction, turnNumber: 0),
              oldWorld: RegionData(),
              newWorld: RegionData(),
            ),
          );
          final shipped = <String, int>{};
          runExtractionPhase(
            game,
            const MapTopology(nodes: [], edges: []),
            const <String, TileMapResult>{},
            <String, Map<CommodityId, int>>{
              'pl1': {CommodityCatalog.grain.id: 10},
            },
            overseasShippedTonnageOut: shipped,
          );
          expect(
            shipped,
            isEmpty,
            reason:
                'scripted extraction path skips overseas auto-transport, '
                'so no cargo holds are committed and no tonnage entries '
                'are recorded',
          );
        },
      );

      test(
        'overseasShippedTonnageOut omitted → backwards-compatible (no '
        'exception, no observable behaviour change)',
        () {
          final (:game, :tileMapByRegion) = extractionAutoTransportFixture(
            nwResourceGrid: const [
              [Resource.sugarCane, Resource.sugarCane],
              [Resource.sugarCane, Resource.sugarCane],
            ],
            nwImprovementLevel: 1,
          );
          final topology = crossRegionSeaTopologyForExtractionTests();
          // Should run cleanly without any tonnage parameter (legacy
          // callers — economy preview pipeline, debug tests).
          final next = runExtractionPhase(
            game,
            topology,
            tileMapByRegion,
            <String, Map<CommodityId, int>>{},
          );
          expect(next, isNotNull);
        },
      );
    },
  );

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
          final acc = TurnPipelineState(game: game);
          final config = TurnResolverConfig(
            topology: topology,
            orders: const Orders(),
            tileMapByRegion: tileMapByRegion,
          );

          final next =
              (extractionTurnPhaseHandler(acc, config, 0)
                      as TurnPhaseStepContinue)
                  .pipeline;

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
          final acc = TurnPipelineState(game: game);
          final config = TurnResolverConfig(
            topology: const MapTopology(nodes: [], edges: []),
            orders: const Orders(),
            extractedByPlayerId: <String, Map<CommodityId, int>>{
              'pl1': {CommodityCatalog.grain.id: 10},
            },
          );

          final next =
              (extractionTurnPhaseHandler(acc, config, 0)
                      as TurnPhaseStepContinue)
                  .pipeline;

          expect(next.overseasExtractionShippedTonnageByPlayerId, isEmpty);
        },
      );
    },
  );
}
