import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'domain_planner_test_fake_api.dart';
import 'planner_test_helpers.dart';

void main() {
  test(
    'belowQuotaPeerGpPeaceTargets peace peer below-quota GP when minors remain',
    () {
      final game = Game(
        id: 'g-peer-below-quota-peace',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
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
                id: 'oldWorld|minor2',
                regionId: 'oldWorld',
                ownerId: 'minor2',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
          Player(id: 'gp6', displayName: 'P6', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor2', displayName: 'M2')],
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
          invadableProvinceIdsSorted: ['oldWorld|minor2'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
        ['gp6'],
      );
      const snapshotGp6 = AIWorldSnapshot(
        playerId: 'gp6',
        threats: ThreatSummary(atWarWith: ['gp5']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 9,
          invadableProvinceIdsSorted: ['oldWorld|minor2'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshotGp6),
        ['gp5'],
      );
    },
  );

  test(
    'belowQuotaPeerGpPeaceTargets peace mutual plateau peer without invadable frontier',
    () {
      final game = Game(
        id: 'g-peer-plateau-no-minors',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
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
          invadableProvinceIdsSorted: const [],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
        ['gp6'],
      );
    },
  );

  test(
    'belowQuotaPeerGpPeaceTargets peace mutual plateau peer on GP-only frontier',
    () {
      final game = Game(
        id: 'g-peer-gp-only-blocker',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp6_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp6',
                ),
              for (var i = 1; i <= 9; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              const Province(
                id: 'oldWorld|frontier',
                regionId: 'oldWorld',
                ownerId: 'gp6',
              ),
              const Province(
                id: 'oldWorld|minor2',
                regionId: 'oldWorld',
                ownerId: 'minor2',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
          Player(id: 'gp6', displayName: 'P6', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor2', displayName: 'M2')],
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
        playerId: 'gp6',
        threats: ThreatSummary(atWarWith: ['gp5']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|frontier'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason: 'sole GP blocker war held on GP-only mutual-plateau frontier',
      );
    },
  );

  test(
    'nearQuotaHoldPeaceTargets peace sole stronger GP at 7 OW',
    () {
      final game = Game(
        id: 'g-near-quota-seven-ow',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 12),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 7; i++)
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
          invadableProvinceIdsSorted: const [],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        ['gp4'],
      );
    },
  );

  test(
    'nearQuotaHoldPeaceTargets peace non-blocker GP wars at 9 OW',
    () {
      final game = Game(
        id: 'g-near-quota-multi-front',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 25),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 9; i++)
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
              for (var i = 1; i <= 7; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              const Province(
                id: 'oldWorld|frontier',
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
          oldWorldProvincesOwned: 9,
          invadableProvinceIdsSorted: ['oldWorld|frontier'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        ['gp5'],
      );
    },
  );

  test(
    'nearQuotaHoldPeaceTargets skips sole GP war at 9 OW',
    () {
      final game = Game(
        id: 'g-near-quota-sole-gp-war',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 25),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 9; i++)
                Province(
                  id: 'oldWorld|gp6_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp6',
                ),
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              const Province(
                id: 'oldWorld|frontier',
                regionId: 'oldWorld',
                ownerId: 'gp5',
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
        playerId: 'gp6',
        threats: ThreatSummary(atWarWith: ['gp5']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 9,
          invadableProvinceIdsSorted: ['oldWorld|frontier'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
      );
    },
  );

  test(
    'nearQuotaHoldPeaceTargets sole GP war at 8 OW peace non-frontier blocker',
    () {
      final game = Game(
        id: 'g-near-quota-sole-gp-war-8',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 25),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp6_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp6',
                ),
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
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
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
          Player(id: 'gp6', displayName: 'P6', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor_f', displayName: 'MF'),
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
        playerId: 'gp6',
        threats: ThreatSummary(atWarWith: ['gp5']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|minor_frontier'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        ['gp5'],
      );
    },
  );

  test(
    'collectStalledGreatPowerPeaceTargets keeps quota-met mop-up vs blocker',
    () {
      final game = Game(
        id: 'g-quota-met-mopup',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 10; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              for (var i = 1; i <= 6; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              const Province(
                id: 'oldWorld|frontier',
                regionId: 'oldWorld',
                ownerId: 'gp3',
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
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['gp3']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 10,
          invadableProvinceIdsSorted: ['oldWorld|frontier'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        collectStalledGreatPowerPeaceTargets(game: game, snapshot: snapshot),
        contains('gp3'),
      );
    },
  );

  test(
    'shouldSkipBelowQuotaGpOnlyBlockerPeacePass false for mutual plateau peer war',
    () {
      final game = Game(
        id: 'g-skip-gp-only-peace',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              for (var i = 1; i <= 8; i++)
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
        shouldSkipBelowQuotaGpOnlyBlockerPeacePass(
          game: game,
          snapshot: snapshot,
        ),
        isFalse,
      );
    },
  );

  test(
    'shouldSkipBelowQuotaGpOnlyBlockerPeacePass false at default start OW',
    () {
      final game = Game(
        id: 'g-skip-gp-only-peace-start-ow',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 7; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              for (var i = 1; i <= 10; i++)
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
        shouldSkipBelowQuotaGpOnlyBlockerPeacePass(
          game: game,
          snapshot: snapshot,
        ),
        isFalse,
      );
    },
  );
}
