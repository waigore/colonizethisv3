import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test(
    'stalledExpansionDistractionPeaceTargets peace tribes not focus minor',
    () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: RegionData(
            provinces: [
              const Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
              const Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
              const Province(
                id: 'oldWorld|p3',
                regionId: 'oldWorld',
                ownerId: 'tribe1',
              ),
            ],
            units: [],
          ),
          newWorld: const RegionData(provinces: [], units: []),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: false,
            leaderKey: 'victoria',
          ),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe')],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 30,
          ),
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'tribe1',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(atWarWith: ['minor1', 'tribe1']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|p2'],
        ),
        economy: EconomySummary(),
        relations: {},
      );

      final targets = stalledExpansionDistractionPeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, ['tribe1']);
    },
  );

  test(
    'stalledStrongerGpBlockerPeaceTarget returns stronger GP in GP-blocker focus',
    () {
      final game = Game(
        id: 'g-gp-blocker-peace',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 7; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              for (var i = 1; i <= 10; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              const Province(
                id: 'oldWorld|inv1',
                regionId: 'oldWorld',
                ownerId: 'gp3',
              ),
              const Province(
                id: 'oldWorld|inv2',
                regionId: 'oldWorld',
                ownerId: 'gp3',
              ),
              const Province(
                id: 'oldWorld|minor1_p1',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['gp3']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|inv1', 'oldWorld|inv2'],
        ),
        economy: EconomySummary(),
        relations: {},
      );

      expect(
        stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot),
        isNull,
      );
    },
  );

  test(
    'stalledStrongerGpBlockerPeaceTarget skips GP peace when no OW minors remain',
    () {
      final game = Game(
        id: 'g-no-minors',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 100),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 7; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              for (var i = 1; i <= 10; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              const Province(
                id: 'oldWorld|inv1',
                regionId: 'oldWorld',
                ownerId: 'gp3',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['gp3']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|inv1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );

      expect(
        stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot),
        isNull,
      );
    },
  );

  test('stalledFutileGpPeaceTargets includes non-invadable GP while at war', () {
    final game = Game(
      id: 'g-futile-gp',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
        oldWorld: RegionData(
          provinces: [
            for (var i = 1; i <= 7; i++)
              Province(
                id: 'oldWorld|gp4_$i',
                regionId: 'oldWorld',
                ownerId: 'gp4',
              ),
            const Province(
              id: 'oldWorld|inv1',
              regionId: 'oldWorld',
              ownerId: 'minor1',
            ),
            for (var i = 1; i <= 7; i++)
              Province(
                id: 'oldWorld|gp2_$i',
                regionId: 'oldWorld',
                ownerId: 'gp2',
              ),
          ],
        ),
        newWorld: const RegionData(),
      ),
      players: const [
        Player(id: 'gp4', displayName: 'P4', isHuman: false),
        Player(id: 'gp2', displayName: 'P2', isHuman: false),
      ],
      minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
      diplomacyRelations: [
        const DiplomacyRelation(
          factionId1: 'gp4',
          factionId2: 'gp2',
          state: RelationState.atWar,
          score: 30,
        ),
      ],
    );
    const snapshot = AIWorldSnapshot(
      playerId: 'gp4',
      threats: ThreatSummary(atWarWith: ['gp2']),
      opportunities: OpportunitySummary(),
      conquest: ConquestSummary(
        oldWorldProvincesOwned: 7,
        invadableProvinceIdsSorted: ['oldWorld|inv1'],
      ),
      economy: EconomySummary(),
      relations: {},
    );

    expect(
      stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
      ['gp2'],
    );
    expect(
      collectStalledGreatPowerPeaceTargets(game: game, snapshot: snapshot),
      contains('gp2'),
    );
  });

  test(
    'criticalWeakGpSurvivalPeaceTargets includes stronger GP when minors are gone',
    () {
      final game = Game(
        id: 'g-weak-survival',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 4; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              for (var i = 1; i <= 12; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              const Province(
                id: 'oldWorld|inv1',
                regionId: 'oldWorld',
                ownerId: 'gp3',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['gp3']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 4,
          invadableProvinceIdsSorted: ['oldWorld|inv1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );

      expect(
        criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot),
        ['gp3'],
      );
      const aboveCollapsed = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['gp3']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 5,
          invadableProvinceIdsSorted: ['oldWorld|inv1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: aboveCollapsed),
        isEmpty,
      );
    },
  );

}
