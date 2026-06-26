import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';


void main() {
  test(
    'stalledBelowQuotaGpLeadPeaceTargets skips invadable GP blocker on GP-only frontier',
    () {
      final game = Game(
        id: 'g-below-quota-skip-blocker',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              for (var i = 1; i <= 9; i++)
                Province(
                  id: 'oldWorld|gp6_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp6',
                ),
              const Province(
                id: 'oldWorld|frontier',
                regionId: 'oldWorld',
                ownerId: 'gp6',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
          Player(id: 'gp6', displayName: 'P6', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp5',
            factionId2: 'gp6',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp5',
        threats: ThreatSummary(atWarWith: ['gp6']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|frontier'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
      );
    },
  );

  test(
    'stalledBelowQuotaGpLeadPeaceTargets skips 1-province lead at default start OW',
    () {
      final game = Game(
        id: 'g-below-quota-no-1-lead',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 70),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 7; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|inv1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
      );
    },
  );

  test(
    'stalledBelowQuotaGpLeadPeaceTargets peace stronger GP while below quota',
    () {
      final game = Game(
        id: 'g-below-quota-gp-lead',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 70),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 1; i <= 12; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4', 'minor1']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|inv1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        ['gp4'],
      );
    },
  );

  test(
    'criticalOwHoldPeaceTargets peace all GP wars below quota without minors',
    () {
      final game = Game(
        id: 'g-critical-below-quota-no-minors',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 5; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 1; i <= 12; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              for (var i = 1; i <= 10; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 30,
          ),
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp5',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4', 'gp5']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 5,
          invadableProvinceIdsSorted: ['oldWorld|inv1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
        ['gp4', 'gp5'],
      );
    },
  );

  test(
    'criticalOwHoldPeaceTargets peace all GP wars at 6 OW below quota',
    () {
      final game = Game(
        id: 'g-critical-six-ow',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 6; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 1; i <= 12; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 6,
          invadableProvinceIdsSorted: const [],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
        ['gp4'],
      );
    },
  );

  test(
    'criticalOwHoldPeaceTargets skips sole GP war at 7 OW (uses other peace paths)',
    () {
      final game = Game(
        id: 'g-critical-below-quota-seven-ow',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 7; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 1; i <= 12; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|inv1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
      );
    },
  );

  test(
    'weakHoldingsInvadableBlockerPeaceTargets peace blocker at 7 OW below quota',
    () {
      final game = Game(
        id: 'g-weak-blocker-below-quota-seven',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 70),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 7; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 1; i <= 10; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              const Province(
                id: 'oldWorld|inv1',
                regionId: 'oldWorld',
                ownerId: 'gp4',
              ),
              const Province(
                id: 'oldWorld|inv2',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|inv1', 'oldWorld|inv2'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        weakHoldingsInvadableBlockerPeaceTargets(game: game, snapshot: snapshot),
        ['gp4'],
      );
    },
  );

  test(
    'weakHoldingsInvadableBlockerPeaceTargets skips blocker on GP-only frontier',
    () {
      final game = Game(
        id: 'g-weak-blocker-gp-only',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 70),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 7; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              for (var i = 1; i <= 9; i++)
                Province(
                  id: 'oldWorld|gp6_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp6',
                ),
              const Province(
                id: 'oldWorld|frontier',
                regionId: 'oldWorld',
                ownerId: 'gp6',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
          Player(id: 'gp6', displayName: 'P6', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp5',
            factionId2: 'gp6',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp5',
        threats: ThreatSummary(atWarWith: ['gp6']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|frontier'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        weakHoldingsInvadableBlockerPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
      );
    },
  );

  test(
    'unwinnableSoleGpFrontierPeaceTarget identifies outgunned sole blocker',
    () {
      final game = Game(
        id: 'g-unwinnable-sole-blocker',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 6; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 1; i <= 10; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              const Province(
                id: 'oldWorld|frontier',
                regionId: 'oldWorld',
                ownerId: 'gp4',
              ),
              const Province(
                id: 'oldWorld|minor1',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 6,
          invadableProvinceIdsSorted: ['oldWorld|frontier', 'oldWorld|minor1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        'gp4',
      );
    },
  );

  test(
    'unwinnableSoleGpFrontierPeaceTarget one-province lead at 8 OW non-GP-only',
    () {
      final game = Game(
        id: 'g-unwinnable-one-lead-8',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 1; i <= 9; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              const Province(
                id: 'oldWorld|minor_frontier',
                regionId: 'oldWorld',
                ownerId: 'minor_f',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor_f', displayName: 'MF'),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|minor_frontier'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        'gp4',
      );
    },
  );

  test(
    'unwinnableSoleGpFrontierPeaceTarget one-province lead at default start OW',
    () {
      final game = Game(
        id: 'g-unwinnable-one-lead-start-ow',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 7; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              const Province(
                id: 'oldWorld|minor_frontier',
                regionId: 'oldWorld',
                ownerId: 'minor_f',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor_f', displayName: 'MF'),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|minor_frontier'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        'gp4',
      );
    },
  );
}
