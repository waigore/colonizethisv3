import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_data/colonizethis_data.dart' show kTechIdTradeFairs;
void main() {
  group('tradeSlotsForGp', () {
    test('returns 0 without embassy', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        ],
        overtureStates: const [],
      );
      expect(tradeSlotsForGp(game, 'gp1', 'minor1'), 0);
    });
    test('returns 3 commodity slots with embassy (baseline)', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        ],
        overtureStates: const [
          OvertureState(gpId: 'gp1', targetId: 'minor1', stage: OvertureStage.embassy, sinceTurn: 0),
        ],
      );
      expect(tradeSlotsForGp(game, 'gp1', 'minor1'), 3);
    });

    test('returns 6 with embassy and trade_fairs', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: true,
            techUnlocked: {kTechIdTradeFairs: true},
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
      expect(tradeSlotsForGp(game, 'gp1', 'minor1'), 6);
    });
  });

  // Refs #2989 A5; SPEC/program/world-market-resolution.md § Bid type cap helper.
  group('worldMarketBidTypeCap', () {
    Game gameWith({
      Map<String, bool> techUnlocked = const {},
      List<OvertureState> overtures = const [],
    }) =>
        Game(
          id: 'g1',
          worldState: WorldState(
            turnState:
                const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'GP1',
              isHuman: true,
              techUnlocked: techUnlocked,
            ),
          ],
          overtureStates: overtures,
        );

    test('returns 0 when player is unknown (ghost-player guard)', () {
      final game = gameWith();
      expect(worldMarketBidTypeCap(game, 'ghost'), 0);
    });

    test(
      'returns kWorldMarketBaselineBidTypeCap (1) when player has no '
      'overtures at all (Refs #2924; SPEC/game/world-market.md § Bid type '
      'cap baseline participation)',
      () {
        final game = gameWith();
        expect(
          worldMarketBidTypeCap(game, 'gp1'),
          kWorldMarketBaselineBidTypeCap,
        );
        expect(kWorldMarketBaselineBidTypeCap, 1);
      },
    );

    test(
      'returns kWorldMarketBaselineBidTypeCap (1) when player has only '
      'trade-consulate overtures (Refs #2924; the baseline cap precedes the '
      'embassy-tier 3-cap upgrade)',
      () {
        final game = gameWith(
          overtures: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.tradeConsulate,
              sinceTurn: 0,
            ),
          ],
        );
        expect(
          worldMarketBidTypeCap(game, 'gp1'),
          kWorldMarketBaselineBidTypeCap,
        );
      },
    );

    test('returns 3 with at least one embassy and no trade_fairs', () {
      final game = gameWith(
        overtures: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );
      expect(worldMarketBidTypeCap(game, 'gp1'), 3);
    });

    test('returns 3 with NAP overture (NAP implies embassy)', () {
      final game = gameWith(
        overtures: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.nap,
            sinceTurn: 0,
          ),
        ],
      );
      expect(worldMarketBidTypeCap(game, 'gp1'), 3);
    });

    test('returns 6 with embassy and trade_fairs', () {
      final game = gameWith(
        techUnlocked: {kTechIdTradeFairs: true},
        overtures: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );
      expect(worldMarketBidTypeCap(game, 'gp1'), 6);
    });

    test(
      'ignores embassies belonging to a different gp (aggregation is '
      'per-player, not global)',
      () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState:
                const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true),
            Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          ],
          overtureStates: const [
            OvertureState(
              gpId: 'gp2',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        expect(
          worldMarketBidTypeCap(game, 'gp1'),
          kWorldMarketBaselineBidTypeCap,
          reason:
              'gp1 is a known player without any embassy of its own, so it '
              'gets the baseline cap of 1 (Refs #2924); gp2 keeps the '
              'embassy-tier 3-cap.',
        );
        expect(worldMarketBidTypeCap(game, 'gp2'), 3);
      },
    );
  });

  group('scoreToLevel', () {
    test('maps score ranges to levels', () {
      expect(scoreToLevel(0), RelationLevel.hostile);
      expect(scoreToLevel(25), RelationLevel.hostile);
      expect(scoreToLevel(26), RelationLevel.neutral);
      expect(scoreToLevel(50), RelationLevel.neutral);
      expect(scoreToLevel(51), RelationLevel.friendly);
      expect(scoreToLevel(75), RelationLevel.friendly);
      expect(scoreToLevel(76), RelationLevel.allied);
      expect(scoreToLevel(100), RelationLevel.allied);
    });
    test('compares decimal scores on the raw value (no rounding)', () {
      expect(scoreToLevel(25.0), RelationLevel.hostile);
      expect(scoreToLevel(25.5), RelationLevel.neutral);
      expect(scoreToLevel(50.0), RelationLevel.neutral);
      expect(scoreToLevel(50.5), RelationLevel.friendly);
      expect(scoreToLevel(75.0), RelationLevel.friendly);
      expect(scoreToLevel(75.5), RelationLevel.allied);
    });
  });

  group('relationMeterStepLabel', () {
    test('returns the 10-word ladder in hostile → friendly order', () {
      expect(relationMeterStepLabels.length, relationMeterStepCount);
      expect(relationMeterStepLabel(1), 'Hostile');
      expect(relationMeterStepLabel(2), 'Antagonistic');
      expect(relationMeterStepLabel(3), 'Distrustful');
      expect(relationMeterStepLabel(4), 'Unfriendly');
      expect(relationMeterStepLabel(5), 'Wary');
      expect(relationMeterStepLabel(6), 'Neutral');
      expect(relationMeterStepLabel(7), 'Cordial');
      expect(relationMeterStepLabel(8), 'Amicable');
      expect(relationMeterStepLabel(9), 'Friendly');
      expect(relationMeterStepLabel(10), 'Devoted');
    });
    test('ladder words are all distinct', () {
      expect(relationMeterStepLabels.toSet().length, relationMeterStepCount);
    });
    test('clamps out-of-range steps to the nearest end word', () {
      expect(relationMeterStepLabel(0), 'Hostile');
      expect(relationMeterStepLabel(-3), 'Hostile');
      expect(relationMeterStepLabel(11), 'Devoted');
    });
  });

  group('relationScoreToDisplayLabel', () {
    test('maps score to the 10-band ladder word (Refs #3753 R13.6)', () {
      // Each band start lands on its step's ladder word.
      expect(relationScoreToDisplayLabel(0), 'Hostile'); // step 1
      expect(relationScoreToDisplayLabel(10), 'Antagonistic'); // step 2
      expect(relationScoreToDisplayLabel(20), 'Distrustful'); // step 3
      expect(relationScoreToDisplayLabel(30), 'Unfriendly'); // step 4
      expect(relationScoreToDisplayLabel(40), 'Wary'); // step 5
      expect(relationScoreToDisplayLabel(50), 'Neutral'); // step 6
      expect(relationScoreToDisplayLabel(60), 'Cordial'); // step 7
      expect(relationScoreToDisplayLabel(70), 'Amicable'); // step 8
      expect(relationScoreToDisplayLabel(80), 'Friendly'); // step 9
      expect(relationScoreToDisplayLabel(90), 'Devoted'); // step 10
      expect(relationScoreToDisplayLabel(100), 'Devoted'); // closed top band
    });
    test('clamps out-of-range score to 0-100', () {
      expect(relationScoreToDisplayLabel(-1), 'Hostile');
      expect(relationScoreToDisplayLabel(101), 'Devoted');
    });
    test('maps decimal scores on the raw value (half-open bands)', () {
      expect(relationScoreToDisplayLabel(9.9), 'Hostile'); // step 1
      expect(relationScoreToDisplayLabel(10.0), 'Antagonistic'); // step 2
      expect(relationScoreToDisplayLabel(22.4), 'Distrustful'); // step 3
      expect(relationScoreToDisplayLabel(49.9), 'Wary'); // step 5
      expect(relationScoreToDisplayLabel(50.0), 'Neutral'); // step 6
    });
  });

  group('relationScoreToMeterStep', () {
    test('maps each integer band start to its 1-based step', () {
      expect(relationScoreToMeterStep(0), 1);
      expect(relationScoreToMeterStep(10), 2);
      expect(relationScoreToMeterStep(20), 3);
      expect(relationScoreToMeterStep(30), 4);
      expect(relationScoreToMeterStep(40), 5);
      expect(relationScoreToMeterStep(50), 6);
      expect(relationScoreToMeterStep(60), 7);
      expect(relationScoreToMeterStep(70), 8);
      expect(relationScoreToMeterStep(80), 9);
      expect(relationScoreToMeterStep(90), 10);
    });

    test('half-open bands map boundary values to the higher step', () {
      // [low, high): the boundary value belongs to the higher step.
      expect(relationScoreToMeterStep(9.9), 1);
      expect(relationScoreToMeterStep(10), 2);
      expect(relationScoreToMeterStep(19.9), 2);
      expect(relationScoreToMeterStep(22.4), 3); // SPEC AC example
      expect(relationScoreToMeterStep(89.999), 9);
    });

    test('final band [90, 100] is fully closed and includes the maximum', () {
      expect(relationScoreToMeterStep(90), 10);
      expect(relationScoreToMeterStep(99.9), 10);
      expect(relationScoreToMeterStep(100), 10);
    });

    test('clamps out-of-range scores to step 1 (below 0) and step 10 (above 100)', () {
      expect(relationScoreToMeterStep(-5), 1);
      expect(relationScoreToMeterStep(-0.1), 1);
      expect(relationScoreToMeterStep(105), 10);
      expect(relationScoreToMeterStep(100.5), 10);
    });

    test('every returned step is within [1, relationMeterStepCount]', () {
      for (var s = -10; s <= 110; s++) {
        final step = relationScoreToMeterStep(s);
        expect(step >= 1 && step <= relationMeterStepCount, isTrue);
      }
    });
  });
}
