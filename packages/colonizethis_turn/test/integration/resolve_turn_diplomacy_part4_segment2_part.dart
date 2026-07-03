part of 'resolve_turn_diplomacy_victory_test.dart';

void _resolve_turn_diplomacy_part4_segment2_partTests() {
  group('part4_segment2_test', () {
    // Regression test for issue #233: Diplomatic orders must flow through
        // OrderEngine and turn resolver to the Diplomacy phase.
        test(
          'validateOrdersAndResolveTurn applies diplomatic orders from OrderEngine',
          () {
            final topology = MapTopology(
              nodes: const [
                TopologyNode(
                  id: 'P1',
                  regionId: 'oldWorld',
                  type: TopologyNodeType.province,
                ),
              ],
              edges: const [],
            );

            const ow = 'oldWorld';
            final game = Game(
              id: 'g1',
              worldState: WorldState(
                turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
                oldWorld: RegionData(
                  provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
                ),
                newWorld: const RegionData(),
              ),
              players: [
                const Player(
                  id: 'p1',
                  displayName: 'P1',
                  isHuman: true,
                  treasury: 2000,
                ).copyWith(techUnlocked: const {kTechIdDiplomaticExpertise: true}),
              ],
              minorNations: const [
                MinorNation(id: 'minor1', displayName: 'Minor 1'),
              ],
              overtureStates: const [],
            );

            // Create OrderEngine with initial diplomatic orders.
            final engine = OrderEngine(
              initialOrders: Orders(
                diplomaticOrdersByPlayerId: {
                  'p1': const [
                    DiplomaticOrder(
                      type: DiplomaticOrderType.establishOverture,
                      targetFactionId: 'minor1',
                      overtureStage: OvertureStage.tradeConsulate,
                    ),
                  ],
                },
              ),
            );

            // Resolve turn via validateOrdersAndResolveTurn (full pipeline).
            final next = requireTurnResolutionComplete(
              validateOrdersAndResolveTurn(
                game: game,
                topology: topology,
                orders:
                    engine.orders, // Start with engine orders (mimics human orders)
              ),
            );

            // Verify diplomatic order was applied: consulate should be established.
            final overture = getOverture(next, 'p1', 'minor1');
            expect(overture, isNotNull);
            expect(overture!.hasConsulate, isTrue);
            // Treasury should be reduced by consulate cost.
            final player = next.playerById('p1')!;
            expect(player.treasury, lessThan(2000));
          },
        );

        test(
          'resolveTurnForGameFromOrderEngine preserves diplomatic orders through merge',
          () {
            final topology = MapTopology(
              nodes: const [
                TopologyNode(
                  id: 'P1',
                  regionId: 'oldWorld',
                  type: TopologyNodeType.province,
                ),
              ],
              edges: const [],
            );

            const ow = 'oldWorld';
            final game = Game(
              id: 'g1',
              worldState: WorldState(
                turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
                oldWorld: RegionData(
                  provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
                ),
                newWorld: const RegionData(),
              ),
              players: const [
                Player(id: 'p1', displayName: 'P1', isHuman: true, treasury: 2000),
              ],
              minorNations: const [
                MinorNation(id: 'minor1', displayName: 'Minor 1'),
              ],
              overtureStates: const [],
            );

            // Create OrderEngine with human diplomatic orders.
            final engine = OrderEngine();
            engine.addDiplomaticOrder(
              'p1',
              const DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'minor1',
              ),
            );

            // AI has no orders.
            final next = requireTurnResolutionComplete(
              resolveTurnForGameFromOrderEngine(
                game: game,
                topology: topology,
                orderEngine: engine,
                aiOrders: const Orders(),
              ),
            );

            // Verify war was declared: relation state should be AT_WAR.
            final rel = getRelation(next, 'p1', 'minor1')!;
            expect(rel.atWar, isTrue);
          },
        );
  });
}
