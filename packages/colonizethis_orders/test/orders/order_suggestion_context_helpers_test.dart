import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_resolution_context.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_pass_context.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_world/src/world/unit_lookup.dart';

void main() {
  final minimalGame = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [Player(id: 'gp1', displayName: 'P1', isHuman: true)],
  );
  const topology = MapTopology(nodes: [], edges: []);

  group('appendDiplomaticOrderForTrial', () {
    test('appends order for existing player list', () {
      const existing = DiplomaticOrder(
        type: DiplomaticOrderType.offerPeace,
        targetFactionId: 'minorA',
      );
      const added = DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: 'minorB',
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': [existing],
        },
      );

      final updated = appendDiplomaticOrderForTrial(orders, 'gp1', added);

      expect(updated.diplomaticOrdersByPlayerId['gp1'], [existing, added]);
      expect(orders.diplomaticOrdersByPlayerId['gp1'], [existing]);
    });

    test('creates new player list when absent', () {
      const added = DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: 'gp2',
      );
      const orders = Orders();

      final updated = appendDiplomaticOrderForTrial(orders, 'gp9', added);

      expect(updated.diplomaticOrdersByPlayerId['gp9'], [added]);
      expect(orders.diplomaticOrdersByPlayerId.containsKey('gp9'), isFalse);
    });
  });

  group('OvertureStageChain.next', () {
    test('follows expected progression', () {
      expect(OvertureStage.none.next, OvertureStage.tradeConsulate);
      expect(OvertureStage.tradeConsulate.next, OvertureStage.embassy);
      expect(OvertureStage.embassy.next, OvertureStage.nap);
      expect(OvertureStage.nap.next, OvertureStage.joinEmpire);
    });

    test('returns null when already at final stage', () {
      expect(OvertureStage.joinEmpire.next, isNull);
    });
  });

  group('OvertureStageChain.previous', () {
    test('next is left inverse of previous for every non-terminal stage', () {
      for (final stage in OvertureStage.values) {
        final forward = stage.next;
        if (forward == null) {
          continue;
        }
        expect(forward.previous, stage);
      }
    });

    test('previous then next restores stage for every stage past none', () {
      for (final stage in OvertureStage.values) {
        if (stage == OvertureStage.none) {
          continue;
        }
        expect(stage.previous.next, stage);
      }
    });

    test('reverses next for progression chain', () {
      for (final stage in [
        OvertureStage.none,
        OvertureStage.tradeConsulate,
        OvertureStage.embassy,
        OvertureStage.nap,
      ]) {
        final forward = stage.next!;
        expect(forward.previous, stage);
      }
    });

    test('none maps to itself', () {
      expect(OvertureStage.none.previous, OvertureStage.none);
    });

    test('joinEmpire previous is nap', () {
      expect(OvertureStage.joinEmpire.previous, OvertureStage.nap);
    });
  });

  group('acceptance wrappers', () {
    test('isNavalMoveOrderAccepted returns a boolean result', () {
      final accepted = isNavalMoveOrderAccepted(
        minimalGame,
        topology,
        'gp1',
        const Orders(),
        const NavalMoveOrder(
          fleetId: 'fleet1',
          destinationSeaZoneId: 'sea1',
        ),
      );
      expect(accepted, isFalse);
    });

    test('isNavalMissionOrderAccepted returns a boolean result', () {
      final accepted = isNavalMissionOrderAccepted(
        minimalGame,
        topology,
        'gp1',
        const Orders(),
        const NavalMissionOrder(
          fleetId: 'fleet1',
          mission: 'patrol',
        ),
      );
      expect(accepted, isFalse);
    });

    test('isDiplomaticOrderAccepted returns a boolean result', () {
      final accepted = isDiplomaticOrderAccepted(
        minimalGame,
        topology,
        'gp1',
        const Orders(),
        const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'minor1',
        ),
      );
      expect(accepted, isFalse);
    });

    test(
      'isDiplomaticOrderAccepted matches default path when view/units shared',
      () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              state: RelationState.atPeace,
              level: RelationLevel.neutral,
            ),
          ],
        );
        const candidate = DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'gp2',
        );
        final sharedView = buildPlayerView(game, topology, 'gp1');
        final sharedUnits = unitsByIdFromWorld(game.worldState);
        final defaultPath = isDiplomaticOrderAccepted(
          game,
          topology,
          'gp1',
          const Orders(),
          candidate,
        );
        final sharedPath = isDiplomaticOrderAccepted(
          game,
          topology,
          'gp1',
          const Orders(),
          candidate,
          resolution: orderResolutionContextFromView(sharedView, game, unitsById: sharedUnits),
        );
        expect(sharedPath, defaultPath);
        expect(defaultPath, isTrue);
      },
    );

    test(
      'stateless accept helpers reuse sharedCandidateValidator without rebuild',
      () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              state: RelationState.atPeace,
              level: RelationLevel.neutral,
            ),
          ],
        );
        const topology = MapTopology(nodes: [], edges: []);
        const baseOrders = Orders();
        final sharedView = buildPlayerView(game, topology, 'gp1');
        final sharedUnits = unitsByIdFromWorld(game.worldState);
        resetIncrementalCandidateValidatorBuildCountForTests();
        final sharedValidator = buildIncrementalCandidateValidator(
          game: game,
          topology: topology,
          playerId: 'gp1',
          baseOrders: baseOrders,
          resolution: orderResolutionContextFromView(sharedView, game, unitsById: sharedUnits),
        );
        expect(incrementalCandidateValidatorBuildCountForTests, 1);

        const candidate = DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'gp2',
        );
        for (var i = 0; i < 5; i++) {
          isDiplomaticOrderAccepted(
            game,
            topology,
            'gp1',
            baseOrders,
            candidate,
            sharedCandidateValidator: sharedValidator,
          );
          isMoveOrderAccepted(
            game,
            topology,
            'gp1',
            baseOrders,
            const MoveOrder(unitId: 'u1', destinationTileKey: 't'),
            sharedCandidateValidator: sharedValidator,
          );
        }
        expect(
          incrementalCandidateValidatorBuildCountForTests,
          1,
          reason:
              'shared validator path must not call buildIncrementalCandidateValidator '
              'per probe (Refs #2394)',
        );
      },
    );

    test(
      'isDiplomaticOrderAcceptedWithValidator matches isDiplomaticOrderAccepted',
      () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              state: RelationState.atPeace,
              level: RelationLevel.neutral,
            ),
          ],
        );
        const topology = MapTopology(nodes: [], edges: []);
        const candidate = DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'gp2',
        );
        const baseOrders = Orders();
        final sharedView = buildPlayerView(game, topology, 'gp1');
        final sharedUnits = unitsByIdFromWorld(game.worldState);
        final validator = buildIncrementalCandidateValidator(
          game: game,
          topology: topology,
          playerId: 'gp1',
          baseOrders: baseOrders,
          resolution: orderResolutionContextFromView(sharedView, game, unitsById: sharedUnits),
        );
        expect(
          isDiplomaticOrderAcceptedWithValidator(validator, candidate),
          isDiplomaticOrderAccepted(
            game,
            topology,
            'gp1',
            baseOrders,
            candidate,
            resolution: orderResolutionContextFromView(sharedView, game, unitsById: sharedUnits),
          ),
        );
      },
    );
  });

  group('order_suggestion_pass_context helpers (Refs #3500 Phase 2)', () {
    test('indexExistingTargetsByEntityId skips empty targets when requested', () {
      final indexed = indexExistingTargetsByEntityId(
        const [
          NavalMoveOrder(
            fleetId: 'f1',
            destinationSeaZoneId: 'seaA',
          ),
          NavalMoveOrder(
            fleetId: 'f1',
            destinationSeaZoneId: '',
          ),
        ],
        (o) => o.fleetId,
        (o) => o.destinationSeaZoneId ?? '',
        skipEmptyTargets: true,
      );
      expect(indexed['f1'], {'seaA'});
    });

    test('emitAcceptedCandidates collects accepted in iteration order', () {
      final into = <NavalMoveOrder>[];
      emitAcceptedCandidates<NavalMoveOrder>(
        candidates: const [
          NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaB'),
          NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaA'),
          NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaC'),
        ],
        // Reject only seaC so we cover both accept and reject branches.
        accept: (o) => o.destinationSeaZoneId != 'seaC',
        into: into,
      );
      expect(
        into.map((o) => o.destinationSeaZoneId).toList(),
        ['seaB', 'seaA'],
        reason: 'preserves candidate order and performs no sorting',
      );
    });

    test('emitAcceptedCandidates skips candidates already targeted', () {
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
      expect(
        into.map((o) => '${o.fleetId}:${o.destinationSeaZoneId}').toList(),
        // f1:seaA is deduped; f2:seaA survives (different entity).
        ['f1:seaB', 'f2:seaA'],
      );
    });

    test('emitAcceptedCandidates probes every candidate without dedup args', () {
      final into = <NavalMoveOrder>[];
      emitAcceptedCandidates<NavalMoveOrder>(
        candidates: const [
          NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaA'),
          NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'seaA'),
        ],
        accept: (_) => true,
        into: into,
        // entityId/dedupKey omitted -> dedup disabled even though duplicates.
        existingByEntity: {
          'f1': {'seaA'},
        },
      );
      expect(into.length, 2);
    });

    test('runCappedSuggestionProbeLoop respects acceptance and probe caps', () {
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
    });

    test('ownedProvinceIdsFromView returns full province ids for owner', () {
      final view = buildPlayerView(
        Game(
          id: 'g-owned',
          worldState: WorldState(
            turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: 'p1', regionId: kOldWorldRegionId, ownerId: 'gp1'),
                Province(id: 'p2', regionId: kOldWorldRegionId, ownerId: 'gp2'),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'P1', isHuman: true),
            Player(id: 'gp2', displayName: 'P2', isHuman: true),
          ],
        ),
        topology,
        'gp1',
      );
      expect(
        ownedProvinceIdsFromView(view, 'gp1'),
        {ProvinceId.full(kOldWorldRegionId, 'p1')},
      );
    });
  });
}
