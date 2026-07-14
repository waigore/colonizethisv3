import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';



// EXPAND-phase scoring suppression cases (former part2 shard, Refs #3941).
void registerDiplomaticCandidateScoringSuppressionExpandBlockerCases() {
  group('computeDiplomaticCandidateScores suppression (part 2)', () {
    test(
      'suppresses mutual plateau declareWar on peer within one OW province',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 8,
            provincesToVictory: 10,
            invadableProvinceIdsSorted: ['oldWorld|p30'],
            adjacentOwnerFactionIdsSorted: ['gp3'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-mutual-plateau-suppress',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 40,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp4_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
                const Province(
                  id: 'oldWorld|p30',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp3', displayName: 'C', isHuman: false),
            Player(id: 'gp4', displayName: 'D', isHuman: false),
          ],
        );
        final score = computeDiplomaticCandidateScores(
          DiplomaticCandidateScoringInput(
            candidates: const [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'gp3',
              ),
            ],
            nationId: 'gp4',
            game: game,
            snapshot: snap,
            config: const AIConfig(
              leaderId: 'henry',
              personalityId: 'henry',
              hiddenAgendaId: 'merchant',
            ),
            primaryGoal: StrategicGoal.conquer,
          ),
        ).single;
        expect(score, 0);
      },
    );

    test(
      'stalledGpBlockerDeclareWarTarget returns GP-only invadable blocker',
      () {
        final game = Game(
          id: 'g-stalled-gp-blocker-declare',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 60,
            ),
            oldWorld: RegionData(
              provinces: [
                const Province(
                  id: 'oldWorld|p30',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
                for (final id in ['p36', 'p37', 'p38', 'p39'])
                  Province(
                    id: 'oldWorld|$id',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
              ],
            ),
            newWorld: const RegionData(),
            armies: [
              Army(
                id: homeArmyIdFor('gp4'),
                ownerId: 'gp4',
                regionId: 'oldWorld',
                stationedProvinceId: 'oldWorld|p36',
                regimentUnitIds: const ['u1'],
                isHomeArmy: true,
              ),
            ],
          ),
          players: const [
            Player(id: 'gp3', displayName: 'C', isHuman: false),
            Player(id: 'gp4', displayName: 'D', isHuman: false),
          ],
        );
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 4,
            invadableProvinceIdsSorted: ['oldWorld|p30'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          stalledGpBlockerDeclareWarTarget(game: game, snapshot: snap),
          'gp3',
        );
      },
    );

    test(
      'stalledGpBlockerDeclareWarTarget skips mutual plateau within one OW on GP-only',
      () {
        final game = Game(
          id: 'g-mutual-plateau-peace-declare',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 60,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 9; i++)
                  Province(
                    id: 'oldWorld|gp6_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp6',
                  ),
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp5_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp5',
                  ),
              ],
            ),
            newWorld: const RegionData(),
            armies: [
              Army(
                id: homeArmyIdFor('gp5'),
                ownerId: 'gp5',
                regionId: 'oldWorld',
                stationedProvinceId: 'oldWorld|gp5_0',
                regimentUnitIds: const ['u_gp5'],
                isHomeArmy: true,
              ),
              Army(
                id: homeArmyIdFor('gp6'),
                ownerId: 'gp6',
                regionId: 'oldWorld',
                stationedProvinceId: 'oldWorld|gp6_0',
                regimentUnitIds: const ['u_gp6'],
                isHomeArmy: true,
              ),
            ],
          ),
          players: const [
            Player(id: 'gp5', displayName: 'P5', isHuman: false),
            Player(id: 'gp6', displayName: 'P6', isHuman: false),
          ],
        );
        const weakerSnap = AIWorldSnapshot(
          playerId: 'gp5',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 8,
            invadableProvinceIdsSorted: ['oldWorld|gp6_8'],
            adjacentOwnerFactionIdsSorted: ['gp6'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        const strongerSnap = AIWorldSnapshot(
          playerId: 'gp6',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 9,
            invadableProvinceIdsSorted: ['oldWorld|gp5_7'],
            adjacentOwnerFactionIdsSorted: ['gp5'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          stalledGpBlockerDeclareWarTarget(game: game, snapshot: weakerSnap),
          'gp6',
        );
        expect(
          stalledGpBlockerDeclareWarTarget(game: game, snapshot: strongerSnap),
          isNull,
        );
      },
    );

  });
}
