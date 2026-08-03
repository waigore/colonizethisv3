// Topic-split case module (Refs #3997 Phase 8).
// Registered from the thin contract / barrel for this family.
// Pin/row coverage is preserved 1:1 from the former combined cases file.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';


void registerDiplomaticScoringSuppressionColonialAdjacentLateCases() {
  group('computeDiplomaticCandidateScores suppression (part 3)', () {
    test(
      'stalled GP at war suppresses declareWar on a second Great Power',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp6',
          threats: ThreatSummary(atWarWith: ['gp3']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            provincesToVictory: 24,
            invadableProvinceIdsSorted: ['oldWorld|p1'],
            adjacentOwnerFactionIdsSorted: ['gp5'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-stalled-second-gp-front',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 20,
            ),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp3', displayName: 'A', isHuman: false),
            Player(id: 'gp5', displayName: 'B', isHuman: false),
            Player(id: 'gp6', displayName: 'C', isHuman: false),
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
                targetFactionId: 'gp5',
              ),
            ],
            nationId: 'gp6',
            game: game,
            snapshot: snap,
            config: config,
          ),
        ).single;
        expect(score, 0);
      },
    );

    test(
      'belowQuotaUninvadedMinorDeclareTarget pivots at 7 OW on GP-only with minors',
      () {
        final game = Game(
          id: 'g-gp-only-minor-pivot-7ow',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 40,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 7; i++)
                  Province(
                    id: 'oldWorld|gp4_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
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
            Player(id: 'gp3', displayName: 'P3', isHuman: false),
            Player(id: 'gp4', displayName: 'P4', isHuman: false),
          ],
          minorNations: const [MinorNation(id: 'minor2', displayName: 'M2')],
        );
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            invadableProvinceIdsSorted: ['oldWorld|gp3_7'],
            adjacentOwnerFactionIdsSorted: ['gp3'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          belowQuotaUninvadedMinorDeclareTarget(game: game, snapshot: snap),
          'minor2',
        );
      },
    );

    test(
      'plateauOwMinorDeclareTarget pivots at 8 OW with sole GP war and minors',
      () {
        final game = Game(
          id: 'g-plateau-minor-sole-gp-war',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 55,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
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
                const Province(
                  id: 'oldWorld|minor3',
                  regionId: 'oldWorld',
                  ownerId: 'minor3',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp3', displayName: 'P3', isHuman: false),
            Player(id: 'gp4', displayName: 'P4', isHuman: false),
          ],
          minorNations: const [MinorNation(id: 'minor3', displayName: 'M3')],
        );
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(atWarWith: ['gp3']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 8,
            invadableProvinceIdsSorted: ['oldWorld|gp3_8', 'oldWorld|minor3'],
            adjacentOwnerFactionIdsSorted: ['gp3', 'minor3'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          plateauOwMinorDeclareTarget(game: game, snapshot: snap),
          'minor3',
        );
      },
    );

    test(
      'belowQuotaUninvadedMinorDeclareTarget pivots at 8 OW on GP-only with minors',
      () {
        final game = Game(
          id: 'g-gp-only-minor-pivot-8ow',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 50,
            ),
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
            Player(id: 'gp5', displayName: 'P5', isHuman: false),
            Player(id: 'gp6', displayName: 'P6', isHuman: false),
          ],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        );
        const snap = AIWorldSnapshot(
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
        expect(
          belowQuotaUninvadedMinorDeclareTarget(game: game, snapshot: snap),
          'minor1',
        );
        expect(
          stalledGpBlockerDeclareWarTarget(game: game, snapshot: snap),
          isNull,
        );
      },
    );

    test(
      'defaultStartOwMinorDeclareTarget pivots on GP-only at 8 OW with minors',
      () {
        final game = Game(
          id: 'g-default-start-gp-only-minor',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 20,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp4_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
                const Province(
                  id: 'oldWorld|minor3',
                  regionId: 'oldWorld',
                  ownerId: 'minor3',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp3', displayName: 'C', isHuman: false),
            Player(id: 'gp4', displayName: 'D', isHuman: false),
          ],
          minorNations: const [MinorNation(id: 'minor3', displayName: 'M3')],
        );
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 8,
            invadableProvinceIdsSorted: ['oldWorld|gp3_7'],
            adjacentOwnerFactionIdsSorted: ['gp3'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          defaultStartOwMinorDeclareTarget(game: game, snapshot: snap),
          'minor3',
        );
      },
    );
  });
}
