import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('resolveNextTurnForGameScreen', () {
    test('passes Full AI orders when map data is available', () {
      final game = Game(
        id: 'g-next-turn-ai',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {'oldWorld|p1|0|0': 'fullyVisible'},
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI GP', isHuman: false),
        ],
        globalGameSeed: 1,
        aiSeedByGpId: const {'gp1': 1},
      );
      final expectedAiResult = generateOrdersForGameFullAI(
        game,
        const MapTopology(nodes: [], edges: []),
      );

      Orders? capturedAiOrders;
      List<TurnTraceAiSection>? capturedAiTraceSections;
      final result = resolveNextTurnForGameScreen(
        game: game,
        orders: const Orders(),
        topologyForAi: const MapTopology(nodes: [], edges: []),
        runTurnResolution:
            ({
              required Orders orders,
              Orders? aiOrders,
              List<TurnTraceAiSection>? aiTraceSections,
            }) {
              capturedAiOrders = aiOrders;
              capturedAiTraceSections = aiTraceSections;
              return TurnResolutionComplete(game);
            },
      );

      expect(result, isA<TurnResolutionComplete>());
      expect(capturedAiOrders, isNotNull);
      expect(capturedAiOrders, equals(expectedAiResult.orders));
      expect(
        capturedAiTraceSections?.map((section) => section.factionId),
        equals(
          expectedAiResult.aiTraceSections.map((section) => section.factionId),
        ),
      );
    });
  });
}
