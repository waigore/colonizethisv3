// Intervention bus integration for GameService event emission (#4734 Slice J).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'game_service_event_emission_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> box;
  late GameSaveAdapter adapter;

  setUpAll(() async {
    box = await openGameServiceEventEmissionHiveBox();
    adapter = GameSaveAdapter();
  });

  test(
    'runTurnResolution emits InterventionRequiredEvent from GameService when resolver returns pending intervention',
    () async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final service = GameService(box, adapter);
      service.eventBus = bus;

      const ow = 'oldWorld';
      const minorProvId = '$ow|M1';
      final game = Game(
        id: 'g_intervention_bus_integration',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: minorProvId, regionId: ow, ownerId: 'minor1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
          Player(
            id: 'gp2',
            displayName: 'Aggressor',
            isHuman: false,
            treasury: 0,
          ),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atPeace,
          ),
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'minor1',
            state: RelationState.atPeace,
          ),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );

      final orders = Orders(
        diplomaticOrdersByPlayerId: const {
          'gp2': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor1',
            ),
          ],
        },
      );

      final received = <AppEvent>[];
      bus.on<InterventionRequiredEvent>().listen(received.add);
      saveRequiredMapDataForGameServiceEventEmission(adapter, box, game.id);

      final result = service.runTurnResolution(game, orders: orders);

      await pumpEventQueue();
      expect(result, isA<TurnResolutionPendingIntervention>());
      expect(received, hasLength(1));
      final event = received.first as InterventionRequiredEvent;
      expect(event.prompts, hasLength(1));
      final prompt = event.prompts.first as InterventionPrompt;
      expect(prompt.aggressorGpId, 'gp2');
      expect(prompt.defenderMinorOrTribeId, 'minor1');
      expect(prompt.interveningGpId, 'gp1');
    },
  );
}
