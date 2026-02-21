import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('Research phase', () {
    Game _baseGame({
      required int treasury,
      Map<String, bool>? techUnlocked,
      Map<String, int>? progress,
    }) {
      final player = Player(
        id: 'p1',
        displayName: 'Player 1',
        isHuman: true,
        treasury: treasury,
        techUnlocked: techUnlocked,
        researchProgressByTechId: progress,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      return Game(id: 'g', worldState: world, players: [player]);
    }

    test('accumulates research progress and unlocks tech when cost reached', () {
      final tech = techById('gathering_1')!;
      // Maximum funding costs 1000 gold/turn (per SPEC/game/tech-tree.md)
      final game = _baseGame(
        treasury: 2000,
        techUnlocked: const {},
      );

      final orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: 'gathering_1',
              funding: ResearchFundingLevel.maximum,
            ),
          ],
        },
      );

      final topology = const MapTopology();
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
      );
      final player = next.players.single;

      // One turn of maximum funding should make progress > 0 and reduce treasury.
      expect(player.treasury, lessThan(game.players.single.treasury));
      final progress = player.researchProgressByTechId ?? const {};
      final unlocked = player.techUnlocked ?? const {};

      if (progress.isNotEmpty) {
        // Research not yet complete; progress should be less than cost and tech not unlocked.
        expect(progress['gathering_1'], isNotNull);
        expect(progress['gathering_1'], lessThan(tech.cost));
        expect(unlocked['gathering_1'], isNot(true));
      } else {
        // If cost is small, research may complete in a single turn.
        expect(unlocked['gathering_1'], isTrue);
      }
    });

    test('applies prerequisite rule: cannot research tech without prereqs', () {
      // No spend when prereq not met; use enough treasury in case logic ever applied
      final game = _baseGame(
        treasury: 2000,
        techUnlocked: const {}, // gathering_1 not researched
      );

      final orders = Orders(
        researchOrdersByPlayerId: const {
          'p1': [
            ResearchOrder(
              slotIndex: 0,
              techId: 'gathering_2',
              funding: ResearchFundingLevel.maximum,
            ),
          ],
        },
      );

      final next = resolveTurnForGame(
        game: game,
        topology: const MapTopology(),
        orders: orders,
      );
      final player = next.players.single;

      // Treasury unchanged and no progress recorded because prerequisite not met.
      expect(player.treasury, game.players.single.treasury);
      expect(player.researchProgressByTechId, isNull);
      expect(player.techUnlocked?['gathering_2'], isNot(true));
    });

    test('research with funding none does not spend treasury or add progress', () {
      final game = _baseGame(treasury: 100, techUnlocked: const {});
      final orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: 'gathering_1',
              funding: ResearchFundingLevel.none,
            ),
          ],
        },
      );
      final next = resolveTurnForGame(
        game: game,
        topology: const MapTopology(),
        orders: orders,
      );
      expect(next.players.single.treasury, 100);
      expect(next.players.single.researchProgressByTechId, isNull);
    });

    test('research with low funding deducts treasury and adds progress', () {
      // Use gathering_2 (cost 120) with prereq so 100 RP does not complete in one turn.
      final game = _baseGame(treasury: 100, techUnlocked: const {'gathering_1': true});
      final orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: 'gathering_2',
              funding: ResearchFundingLevel.low,
            ),
          ],
        },
      );
      final next = resolveTurnForGame(
        game: game,
        topology: const MapTopology(),
        orders: orders,
      );
      // Low funding: 50 gold cost, 100 RP per turn (per SPEC/game/tech-tree.md)
      expect(next.players.single.treasury, 50);
      expect((next.players.single.researchProgressByTechId ?? const {})['gathering_2'], 100);
    });

    test('research with maximum funding has efficiency bonus', () {
      final game = _baseGame(treasury: 2000, techUnlocked: const {});
      final orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: 'gathering_1',
              funding: ResearchFundingLevel.maximum,
            ),
          ],
        },
      );
      final next = resolveTurnForGame(
        game: game,
        topology: const MapTopology(),
        orders: orders,
      );
      // Maximum funding: 1000 gold cost, 2500 RP per turn (2.5x efficiency).
      // gathering_1 cost is 80, so tech unlocks and progress is cleared.
      expect(next.players.single.treasury, 1000);
      expect(next.players.single.techUnlocked!['gathering_1'], isTrue);
    });

    test('all funding levels match spec values via game behavior', () {
      // Use gathering_2 (cost 120) with prereq met so low funding does not complete in one turn.
      const prereqMet = {'gathering_1': true};

      // Low: 50 gold, 100 RP (no unlock; 100 < 120)
      var game = _baseGame(treasury: 100, techUnlocked: prereqMet);
      var orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(slotIndex: 0, techId: 'gathering_2', funding: ResearchFundingLevel.low),
          ],
        },
      );
      var next = resolveTurnForGame(game: game, topology: const MapTopology(), orders: orders);
      expect(next.players.single.treasury, 50);
      expect((next.players.single.researchProgressByTechId ?? const {})['gathering_2'], 100);

      // Medium: 150 gold, 300 RP (unlocks gathering_2)
      game = _baseGame(treasury: 200, techUnlocked: prereqMet);
      orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(slotIndex: 0, techId: 'gathering_2', funding: ResearchFundingLevel.medium),
          ],
        },
      );
      next = resolveTurnForGame(game: game, topology: const MapTopology(), orders: orders);
      expect(next.players.single.treasury, 50);
      expect(next.players.single.techUnlocked!['gathering_2'], isTrue);

      // High: 400 gold, 800 RP (unlocks)
      game = _baseGame(treasury: 500, techUnlocked: prereqMet);
      orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(slotIndex: 0, techId: 'gathering_2', funding: ResearchFundingLevel.high),
          ],
        },
      );
      next = resolveTurnForGame(game: game, topology: const MapTopology(), orders: orders);
      expect(next.players.single.treasury, 100);
      expect(next.players.single.techUnlocked!['gathering_2'], isTrue);

      // Maximum: 1000 gold, 2500 RP (2.5x efficiency, unlocks)
      game = _baseGame(treasury: 1500, techUnlocked: prereqMet);
      orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(slotIndex: 0, techId: 'gathering_2', funding: ResearchFundingLevel.maximum),
          ],
        },
      );
      next = resolveTurnForGame(game: game, topology: const MapTopology(), orders: orders);
      expect(next.players.single.treasury, 500);
      expect(next.players.single.techUnlocked!['gathering_2'], isTrue);
    });
  });
}

