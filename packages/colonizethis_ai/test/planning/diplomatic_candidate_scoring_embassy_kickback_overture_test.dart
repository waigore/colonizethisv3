import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  // Embassy-kickback valuation on `establishOverture` scoring (Refs #3758
  // R7/R8 / S6; #3753 R8.3). Every embassy-holding GP earns
  // `Q × P × relation% × 10%` on each world-market sale from a Minor/Tribe
  // seller, requiring only an embassy (no purchased tile, no Merchant). When
  // the AI does not yet hold an embassy with a Minor/Tribe at peace, advancing
  // the overture toward the embassy stage is valued by the seller's
  // sales-volume proxy and the relation fraction.
  // SPEC/ai/phase-planner-architecture.md § Embassy-kickback overture.
  const config = AIConfig(
    leaderId: 'frederick',
    personalityId: 'frederick',
    hiddenAgendaId: 'merchant',
  );
  const topology = MapTopology(nodes: [], edges: []);

  int scoreCandidate({
    required Game game,
    required List<DiplomaticOrder> candidates,
  }) {
    final snapshot = AIWorldSnapshot.fromPlayerView(
      buildPlayerView(game, topology, 'gp1'),
    );
    return computeDiplomaticCandidateScores(
      candidates: candidates,
      nationId: 'gp1',
      game: game,
      snapshot: snapshot,
      config: config,
    ).single;
  }

  group('computeDiplomaticCandidateScores establishOverture embassy kickback', () {
    // gp1 (AI) owns one Old World province; a Minor seller owns one Old World
    // province with [resourceTileCount] non-empty resource tiles. Keeping the
    // seller in the Old World avoids any New-World colonial-suppression /
    // invadable-owner interaction so only the kickback term varies. The AI's
    // relation with the Minor is the only relation row for the seller, so the
    // AI is always the favoured trading partner (no FTP-competition boost).
    Game gameWithSeller({
      required num ownScore,
      required int resourceTileCount,
      bool holdsEmbassy = false,
    }) {
      final resourceByTileKey = <String, String>{
        for (var i = 0; i < resourceTileCount; i++)
          'oldWorld|m1|$i|0': 'grain',
      };
      return Game(
        id: 'g-embassy-kickback',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(
                id: 'oldWorld|m1',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: resourceByTileKey,
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M')],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: ownScore,
            level: scoreToLevel(ownScore),
            state: RelationState.atPeace,
          ),
        ],
        overtureStates: [
          if (holdsEmbassy)
            const OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
            ),
        ],
      );
    }

    const overtureToMinor = [
      DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: 'minor1',
        overtureStage: OvertureStage.tradeConsulate,
      ),
    ];

    int overtureScore({
      required num ownScore,
      required int resourceTileCount,
      bool holdsEmbassy = false,
    }) => scoreCandidate(
      game: gameWithSeller(
        ownScore: ownScore,
        resourceTileCount: resourceTileCount,
        holdsEmbassy: holdsEmbassy,
      ),
      candidates: overtureToMinor,
    );

    test(
      'high-volume seller adds the full kickback bonus vs a zero-volume seller',
      () {
        // AC12 positive: relation 100 (fraction 1.0), 4 resource tiles
        // (saturates the volume term to 1.0) -> the kickback bonus equals
        // kEstablishOvertureEmbassyKickbackBonusMax above the same overture
        // toward a seller with no resource tiles (no sales volume to value).
        final highVolume = overtureScore(ownScore: 100, resourceTileCount: 4);
        final noVolume = overtureScore(ownScore: 100, resourceTileCount: 0);
        expect(
          highVolume - noVolume,
          kEstablishOvertureEmbassyKickbackBonusMax,
        );
      },
    );

    test('relation fraction scales the kickback bonus', () {
      // relation 50 (fraction 0.5), 4 resource tiles -> half the max bonus.
      final relation50 =
          overtureScore(ownScore: 50, resourceTileCount: 4) -
          overtureScore(ownScore: 50, resourceTileCount: 0);
      expect(
        relation50,
        (kEstablishOvertureEmbassyKickbackBonusMax * 0.5).round(),
      );
      // The same volume at relation 100 yields strictly more than at 50.
      final relation100 =
          overtureScore(ownScore: 100, resourceTileCount: 4) -
          overtureScore(ownScore: 100, resourceTileCount: 0);
      expect(relation100, greaterThan(relation50));
    });

    test('volume proxy scales the bonus linearly below saturation', () {
      // relation 50, 2 of 4 saturating tiles -> round(24 × 0.5 × 0.5) = 6.
      final partial =
          overtureScore(ownScore: 50, resourceTileCount: 2) -
          overtureScore(ownScore: 50, resourceTileCount: 0);
      expect(
        partial,
        (kEstablishOvertureEmbassyKickbackBonusMax * 0.5 * 0.5).round(),
      );
    });

    test('already holding an embassy gets no kickback establishment bonus', () {
      // AC12 negative: when the AI already holds an embassy with the seller the
      // kickback already accrues, so there is no establishment incentive — the
      // high-volume overture scores exactly the no-embassy bonus lower.
      final noEmbassy = overtureScore(ownScore: 100, resourceTileCount: 4);
      final hasEmbassy = overtureScore(
        ownScore: 100,
        resourceTileCount: 4,
        holdsEmbassy: true,
      );
      expect(
        noEmbassy - hasEmbassy,
        kEstablishOvertureEmbassyKickbackBonusMax,
      );
    });
  });

  group('computeDiplomaticCandidateScores establishOverture kickback non-minor', () {
    // The overseas-profit kickback applies only to Minor/Tribe sellers
    // (GP–GP embassies are automatic), so an overture toward a Great Power must
    // never receive the kickback bonus regardless of how many resource tiles
    // that GP owns. SPEC/ai/phase-planner-architecture.md § Embassy-kickback
    // overture.
    Game gameWithGpTarget({required int gpResourceTileCount}) {
      final resourceByTileKey = <String, String>{
        for (var i = 0; i < gpResourceTileCount; i++)
          'oldWorld|p2|$i|0': 'grain',
      };
      return Game(
        id: 'g-embassy-kickback-gp',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: resourceByTileKey,
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 100,
            level: scoreToLevel(100),
            state: RelationState.atPeace,
          ),
        ],
      );
    }

    const overtureToGp = [
      DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: 'gp2',
        overtureStage: OvertureStage.tradeConsulate,
      ),
    ];

    test('Great-Power overture target is invariant to its resource volume', () {
      final manyTiles = scoreCandidate(
        game: gameWithGpTarget(gpResourceTileCount: 8),
        candidates: overtureToGp,
      );
      final noTiles = scoreCandidate(
        game: gameWithGpTarget(gpResourceTileCount: 0),
        candidates: overtureToGp,
      );
      expect(manyTiles, noTiles);
    });
  });
}
