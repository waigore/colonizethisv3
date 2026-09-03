// Tests for the diplomatic standing chip cluster (Refs #3753 R12 / S13).
// Covers SPEC/ui/diplomacy-panel.md § Diplomatic standing chip cluster:
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';

import 'diplomacy_standing_chips_support.dart';

void main() {
  suppressLogsForTests();
  setUp(AppEventBus.reset);

  group('diplomaticStandingChips derivation', () {
    test(
      'AC: colony tribe yields Colony + Embassy chips and no Join Empire',
      () {
        final game = diplomacyStandingColonyTribeGame();
        final chips = diplomaticStandingChips(
          game: game,
          humanPlayerId: 'gp1',
          factionId: 't1',
          kind: FactionKind.tribe,
          relation: const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 't1',
            score: 60,
          ),
          overture: const OvertureState(
            gpId: 'gp1',
            targetId: 't1',
            stage: OvertureStage.embassy,
          ),
          purchasedTiles: PurchasedTileIndex.forTesting(const []),
        );
        expect(chips.treatyLabels, contains(kDiplomacyChipColony));
        expect(chips.treatyLabels, contains(kDiplomacyChipEmbassy));
        expect(chips.treatyLabels, contains(kDiplomacyChipConsulate));
        expect(chips.treatyLabels, isNot(contains(kDiplomacyChipJoinEmpire)));
      },
    );

    test('AC: imposed boycott on the colony yields a "vs" chip name', () {
      final game = diplomacyStandingColonyTribeGame();
      final chips = diplomaticStandingChips(
        game: game,
        humanPlayerId: 'gp1',
        factionId: 't1',
        kind: FactionKind.tribe,
        relation: const DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 't1',
          score: 60,
        ),
        overture: const OvertureState(
          gpId: 'gp1',
          targetId: 't1',
          stage: OvertureStage.embassy,
        ),
        purchasedTiles: PurchasedTileIndex.forTesting(const []),
      );
      expect(chips.boycottVsNames, contains('Castile'));
      expect(chips.boycottedByNames, isEmpty);
    });

    test(
      'AC: foreign colony boycotting the human yields a "Boycotted by" chip',
      () {
        const nw = 'newWorld';
        final game = Game(
          id: 'standing-boycotted-by',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 8),
            oldWorld: const RegionData(),
            newWorld: RegionData(
              provinces: [
                Province(
                  id: '$nw|t2prov',
                  regionId: nw,
                  displayName: 'Foreign Colony Land',
                  ownerId: 't2',
                ),
              ],
            ),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'Albion', isHuman: true),
            Player(id: 'gp2', displayName: 'Castile', isHuman: false),
          ],
          tribes: const [Tribe(id: 't2', displayName: 'Aztec')],
          diplomacyRelations: const [
            DiplomacyRelation(factionId1: 'gp1', factionId2: 't2', score: 45),
          ],
          overtureStates: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 't2',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
          colonyStates: const [
            ColonyState(tribeId: 't2', colonyOfGpId: 'gp2', sinceTurn: 7),
          ],
          boycottStates: const [
            BoycottState(gpId: 'gp2', targetGpId: 'gp1', sinceTurn: 8),
          ],
        );
        final chips = diplomaticStandingChips(
          game: game,
          humanPlayerId: 'gp1',
          factionId: 't2',
          kind: FactionKind.tribe,
          relation: const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 't2',
            score: 45,
          ),
          overture: const OvertureState(
            gpId: 'gp1',
            targetId: 't2',
            stage: OvertureStage.tradeConsulate,
          ),
          purchasedTiles: PurchasedTileIndex.forTesting(const []),
        );
        expect(chips.boycottVsNames, isEmpty);
        expect(chips.boycottedByNames, contains('Castile'));
        expect(chips.treatyLabels, isNot(contains(kDiplomacyChipColony)));
      },
    );

    test('Minor at Join Empire stage yields a Join Empire chip', () {
      final game = Game(
        id: 'standing-minor-je',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Albion', isHuman: true),
        ],
        minorNations: const [MinorNation(id: 'm1', displayName: 'Bavaria')],
      );
      final chips = diplomaticStandingChips(
        game: game,
        humanPlayerId: 'gp1',
        factionId: 'm1',
        kind: FactionKind.minor,
        relation: const DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'm1',
          score: 60,
        ),
        overture: const OvertureState(
          gpId: 'gp1',
          targetId: 'm1',
          stage: OvertureStage.joinEmpire,
        ),
        purchasedTiles: PurchasedTileIndex.forTesting(const []),
      );
      expect(chips.treatyLabels, contains(kDiplomacyChipJoinEmpire));
      expect(chips.treatyLabels, isNot(contains(kDiplomacyChipColony)));
    });

    test('AC: overseas holdings reflect human tile count and rounded share', () {
      final game = Game(
        id: 'standing-overseas',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Albion', isHuman: true),
        ],
        minorNations: const [MinorNation(id: 'm1', displayName: 'Bavaria')],
      );
      final purchased = PurchasedTileIndex.forTesting(const [
        PurchasedTileAttribution(
          tileKey: 'tA',
          owningGpId: 'gp1',
          sourceFactionId: 'm1',
          provinceId: 'newWorld|m1prov',
        ),
        PurchasedTileAttribution(
          tileKey: 'tB',
          owningGpId: 'gp1',
          sourceFactionId: 'm1',
          provinceId: 'newWorld|m1prov',
        ),
        // A tile owned by gp1 but sourced from a different faction is excluded.
        PurchasedTileAttribution(
          tileKey: 'tC',
          owningGpId: 'gp1',
          sourceFactionId: 'm2',
          provinceId: 'newWorld|m2prov',
        ),
      ]);
      final chips = diplomaticStandingChips(
        game: game,
        humanPlayerId: 'gp1',
        factionId: 'm1',
        kind: FactionKind.minor,
        relation: const DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'm1',
          score: 80.4,
        ),
        overture: const OvertureState(
          gpId: 'gp1',
          targetId: 'm1',
          stage: OvertureStage.embassy,
        ),
        purchasedTiles: purchased,
      );
      expect(chips.overseasTileCount, 2);
      expect(chips.overseasSharePercent, 80);
    });

    test('Negative: discovered faction with no standing reports isEmpty', () {
      final game = Game(
        id: 'standing-empty',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Albion', isHuman: true),
        ],
        minorNations: const [MinorNation(id: 'm1', displayName: 'Bavaria')],
      );
      final chips = diplomaticStandingChips(
        game: game,
        humanPlayerId: 'gp1',
        factionId: 'm1',
        kind: FactionKind.minor,
        relation: const DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'm1',
          score: 50,
        ),
        overture: null,
        purchasedTiles: PurchasedTileIndex.forTesting(const []),
      );
      expect(chips.isEmpty, isTrue);
    });
  });
}
