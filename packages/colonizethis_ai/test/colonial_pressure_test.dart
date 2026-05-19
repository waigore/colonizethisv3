import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/colonial_pressure.dart';
import 'package:colonizethis_ai/src/planning/conquest_planner.dart';
import 'package:colonizethis_ai/src/planning/diplomacy_planner_peace_targets.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('hasColonialAcquisitionTargets', () {
    test('true when invadable NW provinces remain', () {
      const colonial = ColonialSummary(
        invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
      );
      expect(hasColonialAcquisitionTargets(colonial), isTrue);
    });

    test('true when adjacent NW tribe owners remain', () {
      const colonial = ColonialSummary(
        adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
      );
      expect(hasColonialAcquisitionTargets(colonial), isTrue);
    });

    test('false when NW holdings exist but no acquisition targets', () {
      const colonial = ColonialSummary(newWorldProvincesOwned: 12);
      expect(hasColonialAcquisitionTargets(colonial), isFalse);
    });
  });

  group('colonialBuildOrderThresholdCap', () {
    test('null when no NW provinces owned', () {
      const colonial = ColonialSummary(
        invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
      );
      expect(colonialBuildOrderThresholdCap(colonial), isNull);
    });

    test('owned NW cap when holdings exist without acquisition targets', () {
      const colonial = ColonialSummary(newWorldProvincesOwned: 10);
      expect(
        colonialBuildOrderThresholdCap(colonial),
        kColonialBuildOrderThresholdWhenOwnedNw,
      );
    });

    test('lower cap when owned NW and acquisition targets remain', () {
      const colonial = ColonialSummary(
        newWorldProvincesOwned: kColonialFewNwProvincesThreshold,
        invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
      );
      expect(
        colonialBuildOrderThresholdCap(colonial),
        kColonialBuildOrderThresholdWhenOwnedNwUnderPressure,
      );
    });
  });

  group('isEarlyColonialExpansion', () {
    test('false when many NW provinces owned despite invadable targets', () {
      const colonial = ColonialSummary(
        newWorldProvincesOwned: kColonialFewNwProvincesThreshold,
        invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
      );
      expect(isEarlyColonialExpansion(colonial), isFalse);
      expect(hasColonialAcquisitionTargets(colonial), isTrue);
    });
  });

  group('belowQuotaPeerGpPeaceTargets', () {
    test('includes mutual plateau peer when no minors remain on the map', () {
      final game = Game(
        id: 'g-below-quota-peer-no-minors',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < 8; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              for (var i = 0; i < 9; i++)
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
        conquest: ConquestSummary(oldWorldProvincesOwned: 8),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
        ['gp6'],
      );
    });
  });

  group('defaultStartFutileMinorPeaceTargets', () {
    test('peaces at-war minors that own no invadable OW at default start size', () {
      final game = Game(
        id: 'g-futile-minor',
        players: [Player(id: 'gp4', displayName: 'GP4', isHuman: false)],
        minorNations: [
          MinorNation(id: 'minor1', displayName: 'M1'),
          MinorNation(id: 'minor2', displayName: 'M2'),
        ],
        tribes: const [],
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 40, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < 7; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              Province(
                id: 'oldWorld|m1',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
              Province(
                id: 'oldWorld|m2',
                regionId: 'oldWorld',
                ownerId: 'minor2',
              ),
            ],
          ),
          newWorld: const RegionData(provinces: []),
        ),
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['minor1']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|m2'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        ['minor1'],
      );
    });

    test('peaces all at-war minors on GP-only invadable frontier', () {
      final game = Game(
        id: 'g-gp-only-minor',
        players: [
          Player(id: 'gp4', displayName: 'GP4', isHuman: false),
          Player(id: 'gp3', displayName: 'GP3', isHuman: false),
        ],
        minorNations: [MinorNation(id: 'minor1', displayName: 'M1')],
        tribes: const [],
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 40, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < 7; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              for (var i = 0; i < 6; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
            ],
          ),
          newWorld: const RegionData(provinces: []),
        ),
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['minor1']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|gp3_0'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        ['minor1'],
      );
    });
  });

  group('defaultStartGpPeaceTargets', () {
    test('peaces all GP wars at 7–8 OW below observer quota', () {
      final game = Game(
        id: 'g',
        players: [
          Player(id: 'gp1', displayName: 'GP1', isHuman: false),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        ],
        minorNations: const [],
        tribes: const [],
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 50, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(provinces: []),
        ),
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(atWarWith: ['gp2']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 8),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
        ['gp2'],
      );
    });

    test('keeps invadable blocker war on GP-only frontier at default start', () {
      final game = Game(
        id: 'g-blocker-peace',
        players: [
          Player(id: 'gp4', displayName: 'GP4', isHuman: false),
          Player(id: 'gp3', displayName: 'GP3', isHuman: false),
        ],
        minorNations: const [],
        tribes: const [],
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 50, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < 7; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              for (var i = 0; i < 6; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
            ],
          ),
          newWorld: const RegionData(provinces: []),
        ),
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
          invadableProvinceIdsSorted: ['oldWorld|gp3_0'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(defaultStartGpPeaceTargets(game: game, snapshot: snapshot), isEmpty);
    });
  });

  group('nearQuotaHoldPeaceTargets', () {
    test('peaces non-blocker GP wars when stalled at 8 OW', () {
      final game = Game(
        id: 'g-near-quota-hold',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 70),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < 8; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 0; i < 10; i++)
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
            score: 20,
          ),
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp5',
            state: RelationState.atWar,
            score: 20,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4', 'gp5']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|frontier'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        contains('gp5'),
      );
    });
  });

  group('criticalOwHoldPeaceTargets', () {
    test('includes GP wars at exactly six OW provinces', () {
      final game = Game(
        id: 'g-critical-ow-hold',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < 6; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              for (var i = 0; i < 12; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
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
            score: 10,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['gp3']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 6),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
        ['gp3'],
      );
    });
  });

  group('belowQuotaActiveMinorWarTarget', () {
    test('returns at-war minor owning invadable provinces', () {
      final game = Game(
        id: 'g-active-minor',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: RegionData(
            provinces: [
              const Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'gp4',
              ),
              const Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 10,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['minor1']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|p2'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        belowQuotaActiveMinorWarTarget(game: game, snapshot: snapshot),
        'minor1',
      );
    });
  });

  group('stalledConquestDeclaredWarTarget', () {
    test('prefers active below-quota minor war over null declare target', () {
      final game = Game(
        id: 'g-conquest-active-minor',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < 7; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              const Province(
                id: 'oldWorld|minor1_cap',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 10,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['minor1']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|p_gp3_only'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        stalledConquestDeclaredWarTarget(
          game: game,
          nationId: 'gp4',
          snapshot: snapshot,
          declaredThisTurn: null,
        ),
        'minor1',
        reason: 'single at-war minor front while stalled below quota',
      );
    });
  });
}
