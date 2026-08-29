// Case bodies for `diplomacy_planner_below_quota_peace_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'diplomacy_planner_below_quota_peace_peer_plateau_cases.dart';

// Peer / near-quota peace helper cases (former part2 shard, Refs #3941).

void registerDiplomacyBelowQuotaPeacePeerCases() {
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

  registerDiplomacyBelowQuotaPeacePeerPlateauCases();
}
