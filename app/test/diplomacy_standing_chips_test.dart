// Tests for the diplomatic standing chip cluster (Refs #3753 R12 / S13).
//
// Covers SPEC/ui/diplomacy-panel.md § Diplomatic standing chip cluster:
//  - `diplomaticStandingChips` derivation (treaty/colony/boycott/overseas),
//  - the `DiplomacyStandingChipCluster` rendering,
//  - the empty-cluster negative case (no chips, zero footprint),
//  - the panel-row integration for a colony Tribe.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';

const MapTopology _emptyTopology = MapTopology(nodes: [], edges: []);

/// Builds a game where the human GP `gp1` holds an Embassy-stage overture with
/// Tribe `t1`, `t1` is a colony of `gp1`, and `gp1` boycotts GP `gp2` (Castile)
/// through that colony.
Game _colonyTribeGame() {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  final home = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'Home',
    ownerId: 'gp1',
  );
  final tribeProvince = Province(
    id: '$nw|t1prov',
    regionId: nw,
    displayName: 'Tribe Land',
    ownerId: 't1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 6),
    oldWorld: RegionData(provinces: [home], units: const []),
    newWorld: RegionData(provinces: [tribeProvince], units: const []),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  return Game(
    id: 'standing-colony',
    worldState: world,
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    tribes: const [Tribe(id: 't1', displayName: 'Powhatan')],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 't1', score: 60),
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', score: 40),
    ],
    overtureStates: const [
      OvertureState(gpId: 'gp1', targetId: 't1', stage: OvertureStage.embassy),
    ],
    colonyStates: const [
      ColonyState(tribeId: 't1', colonyOfGpId: 'gp1', sinceTurn: 5),
    ],
    boycottStates: const [
      BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 6),
    ],
  );
}

Widget _clusterHost(DiplomaticStandingChips chips) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: Center(child: DiplomacyStandingChipCluster(chips: chips)),
    ),
  );
}

void main() {
  suppressLogsForTests();
  setUp(AppEventBus.reset);

  group('diplomaticStandingChips derivation', () {
    test(
      'AC: colony tribe yields Colony + Embassy chips and no Join Empire',
      () {
        final game = _colonyTribeGame();
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
      final game = _colonyTribeGame();
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
        const ow = 'oldWorld';
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
        players: const [Player(id: 'gp1', displayName: 'Albion', isHuman: true)],
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
        players: const [Player(id: 'gp1', displayName: 'Albion', isHuman: true)],
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
        players: const [Player(id: 'gp1', displayName: 'Albion', isHuman: true)],
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

  group('DiplomacyStandingChipCluster widget', () {
    testWidgets('renders treaty, boycott, and overseas chip text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _clusterHost(
          const DiplomaticStandingChips(
            treatyLabels: [kDiplomacyChipEmbassy, kDiplomacyChipColony],
            boycottVsNames: ['Castile'],
            overseasTileCount: 2,
            overseasSharePercent: 80,
          ),
        ),
      );
      await tester.pump();

      expect(find.text(kDiplomacyChipColony), findsOneWidget);
      expect(find.text(kDiplomacyChipEmbassy), findsOneWidget);
      expect(find.text('${kDiplomacyChipBoycottVsPrefix}Castile'), findsOneWidget);
      expect(find.text('${kDiplomacyChipOverseasPrefix}2 \u00b7 80%'), findsOneWidget);
    });

    testWidgets('renders Boycotted by chip for imposed colony embargo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _clusterHost(
          const DiplomaticStandingChips(
            treatyLabels: [kDiplomacyChipColony],
            boycottedByNames: ['Castile'],
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('${kDiplomacyChipBoycottedByPrefix}Castile'),
        findsOneWidget,
      );
    });

    testWidgets('Negative: empty chips render nothing (no Wrap)', (
      tester,
    ) async {
      await tester.pumpWidget(_clusterHost(const DiplomaticStandingChips()));
      await tester.pump();

      expect(find.byType(Wrap), findsNothing);
      expect(find.text(kDiplomacyChipColony), findsNothing);
    });
  });

  testWidgets(
    'panel integration: colony Tribe row shows Colony/Embassy + Boycott vs chips',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(600, 1100));
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.editorialMonocle,
          home: Scaffold(
            body: SizedBox(
              width: 460,
              height: 1000,
              child: DiplomacyPanel(
                game: _colonyTribeGame(),
                humanPlayerId: 'gp1',
                topology: _emptyTopology,
                currentOrders: const Orders(),
                bus: AppEventBus.create(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Powhatan'), findsOneWidget);
      expect(find.text(kDiplomacyChipColony), findsOneWidget);
      expect(find.text(kDiplomacyChipEmbassy), findsWidgets);
      expect(
        find.text('${kDiplomacyChipBoycottVsPrefix}Castile'),
        findsOneWidget,
      );
    },
  );
}
