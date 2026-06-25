import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_turn/src/turn/turn_event_sink.dart';
import 'package:colonizethis_turn/src/turn/turn_resolution_events.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart' show kTechIdBanking;
void main() {
  group('turn resolution dialogue emissions', () {
    test('emitResearchCompleteEvents emits tech_discovered for AI', () {
      final before = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 6),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'ai1',
            displayName: 'AI',
            isHuman: false,
            techUnlocked: {},
          ),
        ],
      );
      final after = before.copyWith(
        players: const [
          Player(
            id: 'ai1',
            displayName: 'AI',
            isHuman: false,
            techUnlocked: {'steam_power': true},
          ),
        ],
      );
      final dialogue = <DialogueEvent>[];
      emitResearchCompleteEvents(
        before,
        after,
        6,
        TurnEventSink(onDialogue: dialogue.add),
      );
      expect(
        dialogue.any(
          (e) =>
              e.category == 'event' &&
              e.situation == 'tech_discovered' &&
              e.leaderId == 'ai1',
        ),
        isTrue,
      );
    });

    test('emitResearchCompleteEvents emits tech_first when human is first', () {
      final before = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 6),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'h1',
            displayName: 'Human',
            isHuman: true,
            techUnlocked: {},
          ),
          Player(id: 'a1', displayName: 'AI', isHuman: false, techUnlocked: {}),
        ],
      );
      final after = before.copyWith(
        players: const [
          Player(
            id: 'h1',
            displayName: 'Human',
            isHuman: true,
            techUnlocked: {kTechIdBanking: true},
          ),
          Player(id: 'a1', displayName: 'AI', isHuman: false, techUnlocked: {}),
        ],
      );
      final dialogue = <DialogueEvent>[];
      emitResearchCompleteEvents(
        before,
        after,
        6,
        TurnEventSink(onDialogue: dialogue.add),
      );
      expect(
        dialogue.any(
          (e) =>
              e.category == 'reactive' &&
              e.situation == 'tech_first' &&
              e.leaderId == 'a1',
        ),
        isTrue,
      );
    });

    test(
      'emitProvinceCapturedEvents emits colony_founded for New World null->AI',
      () {
        final after = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: const RegionData(),
            newWorld: RegionData(
              provinces: const [
                Province(
                  id: 'newWorld|N1',
                  regionId: 'newWorld',
                  ownerId: 'a1',
                ),
              ],
            ),
          ),
          players: const [Player(id: 'a1', displayName: 'AI', isHuman: false)],
        );
        final dialogue = <DialogueEvent>[];
        emitProvinceCapturedEvents(
          const {'newWorld|N1': null},
          after,
          2,
          TurnEventSink(onDialogue: dialogue.add),
        );
        expect(
          dialogue.any(
            (e) =>
                e.category == 'event' &&
                e.situation == 'colony_founded' &&
                e.leaderId == 'a1',
          ),
          isTrue,
        );
      },
    );

    group('emitProvinceCapturedEvents', () {
      test(
        'Given previous owner set and new owner null When emit Then no province_captured',
        () {
          const fullPid = 'oldWorld|P1';
          final after = Game(
            id: 'g',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: RegionData(
                provinces: [
                  Province(id: fullPid, regionId: 'oldWorld', ownerId: null),
                ],
              ),
              newWorld: const RegionData(),
            ),
            players: const [
              Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
            ],
          );
          final captured = <GameEvent>[];
          emitProvinceCapturedEvents(
            {fullPid: 'gp1'},
            after,
            1,
            TurnEventSink(onGameEvent: captured.add),
          );
          expect(captured, isEmpty);
        },
      );

      test('Given gp1 to gp2 When emit Then one ProvinceCapturedEvent', () {
        const fullPid = 'oldWorld|P1';
        final after = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: fullPid, regionId: 'oldWorld', ownerId: 'gp2'),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
            Player(id: 'gp2', displayName: 'B', isHuman: false, treasury: 0),
          ],
        );
        final captured = <GameEvent>[];
        emitProvinceCapturedEvents(
          {fullPid: 'gp1'},
          after,
          1,
          TurnEventSink(onGameEvent: captured.add),
        );
        expect(captured, hasLength(1));
        final e = captured.single as ProvinceCapturedEvent;
        expect(e.provinceId, fullPid);
        expect(e.previousOwnerId, 'gp1');
        expect(e.newOwnerId, 'gp2');
      });
    });
  });
}
