import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

List<String> _combatMessages(List<LogEvent> events) => [
  for (final e in events)
    if (e.message.contains('logic: combat')) e.message,
];

void main() {
  group('land combat logging', () {
    late List<LogEvent> capturedEvents;
    late void Function(LogEvent) listener;

    setUp(() {
      capturedEvents = [];
      listener = capturedEvents.add;
      Logger.addLogListener(listener);
      Logger.level = Level.debug;
    });

    tearDown(() {
      Logger.removeLogListener(listener);
      capturedEvents.clear();
      Logger.level = Level.info;
    });

    test(
      'resolveBattleContext emits engagement (debug) and battle_apply (info)',
      () {
        final attackerUnits = [
          Unit(
            id: 'a1',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
            medals: 3,
          ),
          Unit(
            id: 'a2',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
            medals: 2,
          ),
        ];
        final defenderUnits = [
          Unit(
            id: 'd1',
            type: 'peasant_levies',
            ownerId: 'def',
            locationProvinceId: 'p',
            medals: 0,
          ),
        ];
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'p', regionId: 'oldWorld', ownerId: 'def'),
              ],
              units: [...attackerUnits, ...defenderUnits],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(
              id: 'att',
              displayName: 'France',
              isHuman: true,
              leaderKey: 'napoleon',
            ),
            Player(
              id: 'def',
              displayName: 'Prussia',
              isHuman: false,
              leaderKey: 'frederick',
            ),
          ],
        );
        const ctx = BattleContext(
          provinceId: 'p',
          regionId: 'oldWorld',
          defenderFactionId: 'def',
          defenderUnitIds: ['d1'],
          attackers: [
            AttackingSide(factionId: 'att', unitIds: ['a1', 'a2']),
          ],
          fortLevel: 0,
          terrain: 'plains',
        );

        resolveBattleContext(game, ctx);

        final combat = _combatMessages(capturedEvents);
        expect(
          combat.where((m) => m.contains('logic: combat engagement')).length,
          1,
        );
        final engagement = combat.firstWhere(
          (m) => m.contains('logic: combat engagement'),
        );
        expect(engagement, contains('result='));
        expect(engagement, contains('attackerFactionId=att'));
        expect(engagement, contains('attCasualties='));
        expect(engagement, contains('defCasualties='));

        final apply = combat.firstWhere(
          (m) => m.contains('logic: combat battle_apply'),
        );
        expect(apply, contains('mode=autoResolve'));
        expect(apply, contains('provinceFlipped='));
        expect(apply, contains('casualtiesApplied='));
        expect(apply, contains('ownerAfter='));

        expect(
          capturedEvents.any(
            (e) =>
                e.level == Level.debug &&
                e.message.contains('logic: combat engagement'),
          ),
          isTrue,
        );
        expect(
          capturedEvents.any(
            (e) =>
                e.level == Level.info &&
                e.message.contains('logic: combat battle_apply'),
          ),
          isTrue,
        );
      },
    );

    test('two attacker sides emit one debug line per executed engagement', () {
      // First attacker must lose (defender still holds); otherwise a decisive
      // first attacker victory skips remaining attackers (no second engagement).
      final game = Game(
        id: 'g1',
        globalGameSeed: 1234,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 8),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'p', regionId: 'oldWorld', ownerId: 'def'),
            ],
            units: [
              Unit(
                id: 'a1',
                type: 'peasant_levies',
                ownerId: 'attA',
                locationProvinceId: 'p',
              ),
              Unit(
                id: 'a2',
                type: 'peasant_levies',
                ownerId: 'attB',
                locationProvinceId: 'p',
              ),
              Unit(
                id: 'd1',
                type: 'grenadiers',
                ownerId: 'def',
                locationProvinceId: 'p',
                medals: 2,
              ),
              Unit(
                id: 'd2',
                type: 'grenadiers',
                ownerId: 'def',
                locationProvinceId: 'p',
                medals: 2,
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'attA', displayName: 'A', isHuman: true),
          Player(id: 'attB', displayName: 'B', isHuman: true),
          Player(id: 'def', displayName: 'D', isHuman: true),
        ],
      );
      const ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1', 'd2'],
        attackers: [
          AttackingSide(factionId: 'attA', unitIds: ['a1']),
          AttackingSide(factionId: 'attB', unitIds: ['a2']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      resolveBattleContext(game, ctx);

      final engagementLines = _combatMessages(
        capturedEvents,
      ).where((m) => m.contains('logic: combat engagement')).toList();
      expect(engagementLines.length, 2);
      expect(
        engagementLines
            .where((m) => m.contains('attackerFactionId=attA'))
            .length,
        1,
      );
      expect(
        engagementLines
            .where((m) => m.contains('attackerFactionId=attB'))
            .length,
        1,
      );
    });

    test(
      'Combat phase logs conflict_detection and battle_start for moved-in attack',
      () {
        final topology = MapTopology(
          nodes: [
            const TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            const TopologyNode(
              id: 'P2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
        );

        const ow = 'oldWorld';
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'grenadiers',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                  medals: 2,
                ),
                Unit(
                  id: 'u2',
                  type: 'peasant_levies',
                  ownerId: 'p2',
                  locationProvinceId: '$ow|P2',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(id: 'p1', displayName: 'A', isHuman: true, militaryLevel: 3),
            Player(id: 'p2', displayName: 'B', isHuman: true, militaryLevel: 1),
          ],
        );

        final orders = Orders(
          moveOrdersByPlayerId: {
            'p1': [MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2')],
          },
        );

        requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: orders,
            extractedByPlayerId: const {},
            defaultAssignments: const [],
          ),
        );

        final combat = _combatMessages(capturedEvents);
        expect(
          combat.any(
            (m) => m.contains('logic: combat conflict_detection start'),
          ),
          isTrue,
        );
        expect(
          combat.any(
            (m) =>
                m.contains('logic: combat conflict_detection end') &&
                m.contains('battleContexts=1'),
          ),
          isTrue,
        );
        expect(
          combat.any(
            (m) =>
                m.contains('logic: combat battle_start') &&
                m.contains('attackerSides=1') &&
                m.contains('attackerUnitsTotal=1') &&
                m.contains('mode=autoResolve'),
          ),
          isTrue,
        );
        expect(
          combat.any((m) => m.contains('logic: combat engagement')),
          isTrue,
        );
        expect(
          combat.any(
            (m) =>
                m.contains('logic: combat battle_apply') &&
                m.contains('mode=autoResolve'),
          ),
          isTrue,
        );
        expect(
          capturedEvents.any(
            (e) =>
                e.level == Level.info &&
                e.message.contains('logic: phase combat start'),
          ),
          isTrue,
        );
        expect(
          capturedEvents.any(
            (e) =>
                e.level == Level.info &&
                e.message.contains('logic: phase combat end'),
          ),
          isTrue,
        );
      },
    );

    test(
      'Quick Battle path logs battle_apply quickBattle not auto engagement',
      () {
        final topology = MapTopology(
          nodes: [
            const TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            const TopologyNode(
              id: 'P2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
        );

        const ow = 'oldWorld';
        final game = Game(
          id: 'g1',
          defaultCombatMode: CombatMode.quickBattle,
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'grenadiers',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                  medals: 2,
                ),
                Unit(
                  id: 'u2',
                  type: 'peasant_levies',
                  ownerId: 'p2',
                  locationProvinceId: '$ow|P2',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(id: 'p1', displayName: 'A', isHuman: true, militaryLevel: 3),
            Player(id: 'p2', displayName: 'B', isHuman: true, militaryLevel: 1),
          ],
        );

        final orders = Orders(
          moveOrdersByPlayerId: {
            'p1': [MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2')],
          },
        );

        requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: orders,
            extractedByPlayerId: const {},
            defaultAssignments: const [],
          ),
        );

        final combat = _combatMessages(capturedEvents);
        expect(
          combat.any(
            (m) =>
                m.contains('logic: combat battle_start') &&
                m.contains('mode=quickBattle'),
          ),
          isTrue,
        );
        expect(
          combat.any(
            (m) =>
                m.contains('logic: combat battle_apply') &&
                m.contains('mode=quickBattle') &&
                m.contains('winner='),
          ),
          isTrue,
        );
        expect(
          combat.any((m) => m.contains('logic: combat engagement')),
          isFalse,
        );
      },
    );

    test(
      'no land battles still logs conflict_detection end with battleContexts=0',
      () {
        final topology = MapTopology(
          nodes: [
            const TopologyNode(
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
              units: [
                Unit(
                  id: 'u1',
                  type: 'grenadiers',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                  medals: 2,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(id: 'p1', displayName: 'A', isHuman: true, militaryLevel: 3),
          ],
        );

        requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: const Orders(),
            extractedByPlayerId: const {},
            defaultAssignments: const [],
          ),
        );

        final combat = _combatMessages(capturedEvents);
        expect(
          combat.any(
            (m) =>
                m.contains('logic: combat conflict_detection end') &&
                m.contains('battleContexts=0'),
          ),
          isTrue,
        );
        expect(
          combat.any((m) => m.contains('logic: combat battle_start')),
          isFalse,
        );
      },
    );
  });
}
