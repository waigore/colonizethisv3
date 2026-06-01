import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
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
  });

  group('relationScoreToDisplayLabel', () {
    test('maps score to display label per SPEC/game/diplomacy.md § Player-facing relation display', () {
      expect(relationScoreToDisplayLabel(0), 'Hostile');
      expect(relationScoreToDisplayLabel(29), 'Hostile');
      expect(relationScoreToDisplayLabel(30), 'Unfriendly');
      expect(relationScoreToDisplayLabel(49), 'Unfriendly');
      expect(relationScoreToDisplayLabel(50), 'Cordial');
      expect(relationScoreToDisplayLabel(69), 'Cordial');
      expect(relationScoreToDisplayLabel(70), 'Friendly');
      expect(relationScoreToDisplayLabel(100), 'Friendly');
    });
    test('clamps out-of-range score to 0-100', () {
      expect(relationScoreToDisplayLabel(-1), 'Hostile');
      expect(relationScoreToDisplayLabel(101), 'Friendly');
    });
  });
}
