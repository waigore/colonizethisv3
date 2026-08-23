// DiplomacyStandingChipCluster widget ACs (Refs #4606 Slice D).
// Host: diplomacy_standing_chips_test.dart.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';

import 'app_shell_harness.dart';

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
  return buildAppShell(
    child: Scaffold(
      body: Center(child: DiplomacyStandingChipCluster(chips: chips)),
    ),
  );
}

void main() {
  suppressLogsForTests();
  setUp(AppEventBus.reset);

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
      expect(
        find.text('${kDiplomacyChipBoycottVsPrefix}Castile'),
        findsOneWidget,
      );
      expect(
        find.text('${kDiplomacyChipOverseasPrefix}2 \u00b7 80%'),
        findsOneWidget,
      );
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
        buildAppShell(
          child: Scaffold(
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
