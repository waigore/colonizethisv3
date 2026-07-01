import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/src/turn/spy_resolver.dart';
import 'package:colonizethis_turn/src/turn/turn_resolution_events.dart';

void main() {
  group('emitSpyResolutionEvents', () {
    test('emits SpyCaughtEvent for each killed spy in unitId order', () {
      const game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 4),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        ],
      );
      const result = SpyResolutionResult(
        game: game,
        caughtSpies: [
          SpyCaughtDetail(
            unitId: 'spy_b',
            spyOwnerId: 'gp2',
            territoryOwnerId: 'gp1',
            provinceId: 'oldWorld|p2',
          ),
          SpyCaughtDetail(
            unitId: 'spy_a',
            spyOwnerId: 'gp2',
            territoryOwnerId: 'gp1',
            provinceId: 'oldWorld|p1',
          ),
        ],
      );
      final events = <GameEvent>[];
      emitSpyResolutionEvents(
        game,
        result,
        4,
        TurnEventSink(onGameEvent: events.add),
      );

      expect(events, hasLength(2));
      expect(events[0], isA<SpyCaughtEvent>());
      final first = events[0] as SpyCaughtEvent;
      expect(first.unitId, 'spy_a');
      expect(first.spyOwnerId, 'gp2');
      expect(first.territoryOwnerId, 'gp1');
      expect(first.provinceId, 'oldWorld|p1');
      expect(first.turnNumber, 4);
      final second = events[1] as SpyCaughtEvent;
      expect(second.unitId, 'spy_b');
    });

    test('emits SpyDefectedEvent for each defection in unitId order', () {
      const game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        ],
      );
      const result = SpyResolutionResult(
        game: game,
        defectedSpies: [
          SpyDefectedDetail(
            unitId: 'spy_z',
            previousOwnerId: 'gp2',
            newOwnerId: 'gp1',
            provinceId: 'oldWorld|p3',
          ),
        ],
      );
      final events = <GameEvent>[];
      emitSpyResolutionEvents(
        game,
        result,
        5,
        TurnEventSink(onGameEvent: events.add),
      );

      expect(events, hasLength(1));
      final evt = events.single as SpyDefectedEvent;
      expect(evt.unitId, 'spy_z');
      expect(evt.previousOwnerId, 'gp2');
      expect(evt.newOwnerId, 'gp1');
      expect(evt.provinceId, 'oldWorld|p3');
      expect(evt.turnNumber, 5);
    });

    test('emits reactive spies_caught dialogue when AI catches human spy', () {
      final game = Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 6),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final result = SpyResolutionResult(
        game: game,
        caughtSpies: const [
          SpyCaughtDetail(
            unitId: 'spy1',
            spyOwnerId: 'gp1',
            territoryOwnerId: 'gp2',
            provinceId: 'oldWorld|p1',
          ),
        ],
      );
      final dialogue = <DialogueEvent>[];
      emitSpyResolutionEvents(
        game,
        result,
        6,
        TurnEventSink(onDialogue: dialogue.add),
      );
      expect(
        dialogue.any(
          (e) =>
              e.category == 'reactive' &&
              e.situation == 'spies_caught' &&
              e.leaderId == 'gp2',
        ),
        isTrue,
      );
    });

    test('emits reactive spies_defected dialogue when AI gains human spy', () {
      final game = Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 7),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final result = SpyResolutionResult(
        game: game,
        defectedSpies: const [
          SpyDefectedDetail(
            unitId: 'spy1',
            previousOwnerId: 'gp1',
            newOwnerId: 'gp2',
            provinceId: 'oldWorld|p1',
          ),
        ],
      );
      final dialogue = <DialogueEvent>[];
      emitSpyResolutionEvents(
        game,
        result,
        7,
        TurnEventSink(onDialogue: dialogue.add),
      );
      expect(
        dialogue.any(
          (e) =>
              e.category == 'reactive' &&
              e.situation == 'spies_defected' &&
              e.leaderId == 'gp2',
        ),
        isTrue,
      );
    });
  });
}
