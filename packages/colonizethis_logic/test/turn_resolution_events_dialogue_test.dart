import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/src/turn/turn_resolution_events.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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
      emitResearchCompleteEvents(before, after, 6, null, null, dialogue.add);
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
            techUnlocked: {'banking': true},
          ),
          Player(id: 'a1', displayName: 'AI', isHuman: false, techUnlocked: {}),
        ],
      );
      final dialogue = <DialogueEvent>[];
      emitResearchCompleteEvents(before, after, 6, null, null, dialogue.add);
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
          null,
          null,
          dialogue.add,
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
  });
}
