import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';


// Core diplomatic candidate scoring suppression cases (Refs #3941).
void registerDiplomaticCandidateScoringSuppressionCoreEarlyCases() {
  group('computeDiplomaticCandidateScores suppression', () {
    test(
      'colonial-adjacent tribe declareWar is not suppressed when only OW-adjacent list is empty',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
            provincesToVictory: 24,
            adjacentOwnerFactionIdsSorted: [],
          ),
          colonial: ColonialSummary(
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-colonial-tribe',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
          ],
          tribes: const [
            Tribe(id: 'tribe1', displayName: 'T1'),
          ],
        );
        const config = AIConfig(
          leaderId: 'henry',
          personalityId: 'henry',
          hiddenAgendaId: 'merchant',
        );
        final score = computeDiplomaticCandidateScores(
          DiplomaticCandidateScoringInput(
            candidates: const [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'tribe1',
              ),
            ],
            nationId: 'gp1',
            game: game,
            snapshot: snap,
            config: config,
          ),
        ).single;
        expect(score, greaterThan(0));
        expect(score, greaterThanOrEqualTo(kDeclareWarColonialAdjacentTribeBonus));
      },
    );

    test(
      'stalled OW expansion prioritizes adjacent minor over tribe without NW provinces',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            provincesToVictory: 24,
            invadableProvinceIdsSorted: ['oldWorld|minor1'],
            adjacentOwnerFactionIdsSorted: ['minor1'],
          ),
          colonial: ColonialSummary(
            invadableNewWorldProvinceIdsSorted: ['newWorld|nw1'],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-stalled-ow-minor',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|minor1',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
              ],
            ),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: 'newWorld|nw1',
                  regionId: 'newWorld',
                  ownerId: 'tribe1',
                ),
              ],
            ),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'M1'),
          ],
          tribes: const [
            Tribe(id: 'tribe1', displayName: 'T1'),
          ],
        );
        const config = AIConfig(
          leaderId: 'henry',
          personalityId: 'henry',
          hiddenAgendaId: 'peacemaker',
        );
        final scores = computeDiplomaticCandidateScores(
          DiplomaticCandidateScoringInput(
            candidates: const [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'tribe1',
              ),
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'minor1',
              ),
            ],
            nationId: 'gp1',
            game: game,
            snapshot: snap,
            config: config,
          ),
        );
        expect(scores[1], greaterThan(scores[0]));
      },
    );

  });
}
