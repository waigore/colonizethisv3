// Widget goldens for the diplomacy detail screen (GAME30002) visual acceptance
// criteria (Refs #3753 S17 / R12 / R13). The panel row gained standing-chip
// and 10-step relation-meter goldens in `diplomacy_panel_goldens_test.dart`
// (#3815); this file closes the matching pixel baselines for the detail
// screen's `CURRENT RELATION` card, which renders the same
// `DiplomacyStandingChipCluster` and `RelationMeter` below the relation
// summary per SPEC/ui/diplomacy-detail-screen.md § States and variants.
//
// Outgoing subsidy/grant copy from the list row is intentionally absent on
// the detail screen (see diplomacy-detail-screen.md § Layout).
//
// SPEC: SPEC/ui/diplomacy-detail-screen.md; SPEC/ui/diplomacy-panel.md §
// Diplomatic standing chip cluster acceptance criteria (Refs #3753 R12).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy_detail_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/relation_meter.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/widget_test_assets.dart';

Future<void> _pumpBuilt(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

Widget _detailHost({
  required Game game,
  required String humanPlayerId,
  required String factionId,
  required String factionDisplayName,
  required FactionKind kind,
  required Key boundaryKey,
  DiplomacyRelation? relation,
}) {
  return ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RepaintBoundary(
        key: boundaryKey,
        child: DiplomacyDetailScreen(
          game: game,
          humanPlayerId: humanPlayerId,
          factionId: factionId,
          factionDisplayName: factionDisplayName,
          kind: kind,
          relation: relation ?? getRelation(game, humanPlayerId, factionId),
        ),
      ),
    ),
  );
}

/// Refs #3753 R12/R13: colony Tribe with standing chips + relation meter.
Game _colonyTribeDetailGame() {
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
    id: 'diplo-detail-golden-colony-tribe',
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
    diplomaticHistoryEvents: const [
      DiplomaticEvent(
        turn: 5,
        intraTurnIndex: 0,
        type: DiplomaticEventType.overtureAccepted,
        participants: {'gp1', 't1'},
        fromFactionId: 'gp1',
        toFactionId: 't1',
        overtureStage: OvertureStage.embassy,
      ),
    ],
  );
}

/// Refs #3753 R3/R8/R12: subsidized Minor with overseas holdings chip.
Game _subsidizedMinorDetailGame() {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  const minorProvinceId = '$nw|m1prov';
  const tileA = '$minorProvinceId|0|0';
  const tileB = '$minorProvinceId|1|0';
  final home = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'Home',
    ownerId: 'gp1',
  );
  final minorProvince = Province(
    id: minorProvinceId,
    regionId: nw,
    displayName: 'Bavaria Coast',
    ownerId: 'm1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 8),
    oldWorld: RegionData(provinces: [home], units: const []),
    newWorld: RegionData(provinces: [minorProvince], units: const []),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
    purchasedTilesByTileKey: const {tileA: 'gp1', tileB: 'gp1'},
    tileKeysByRegionAndProvince: const {
      nw: {
        minorProvinceId: [tileA, tileB],
      },
    },
  );
  return Game(
    id: 'diplo-detail-golden-subsidized-minor',
    worldState: world,
    players: const [Player(id: 'gp1', displayName: 'Albion', isHuman: true)],
    minorNations: const [MinorNation(id: 'm1', displayName: 'Bavaria')],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'm1', score: 80),
    ],
    overtureStates: const [
      OvertureState(gpId: 'gp1', targetId: 'm1', stage: OvertureStage.embassy),
    ],
    subsidyStates: const [
      SubsidyState(payerId: 'gp1', targetId: 'm1', percent: 10),
    ],
    diplomaticHistoryEvents: const [
      DiplomaticEvent(
        turn: 7,
        intraTurnIndex: 0,
        type: DiplomaticEventType.subsidySet,
        participants: {'gp1', 'm1'},
        fromFactionId: 'gp1',
        toFactionId: 'm1',
        amount: 10,
      ),
    ],
  );
}

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await preloadNinePatchImage();
  });

  setUp(AppEventBus.reset);

  testWidgets(
    'GAME30002 golden: colony Tribe detail shows standing chips + relation meter',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(600, 900));
      const boundaryKey = ValueKey<String>(
        'diplomacy_detail_colony_tribe_golden',
      );

      final game = _colonyTribeDetailGame();
      await tester.pumpWidget(
        _detailHost(
          game: game,
          humanPlayerId: 'gp1',
          factionId: 't1',
          factionDisplayName: 'Powhatan',
          kind: FactionKind.tribe,
          boundaryKey: boundaryKey,
        ),
      );
      await _pumpBuilt(tester);

      expect(find.text('CURRENT RELATION'), findsOneWidget);
      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      expect(find.text(kDiplomacyChipColony), findsOneWidget);
      expect(find.text(kDiplomacyChipEmbassy), findsWidgets);
      expect(
        find.text('${kDiplomacyChipBoycottVsPrefix}Castile'),
        findsOneWidget,
      );
      expect(find.byType(RelationMeter), findsOneWidget);
      expect(find.text('Outgoing subsidy:'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_detail_colony_tribe.png'),
      );
    },
  );

  testWidgets(
    'GAME30002 golden: subsidized Minor detail shows overseas chip + relation meter',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(600, 900));
      const boundaryKey = ValueKey<String>(
        'diplomacy_detail_subsidized_minor_golden',
      );

      final game = _subsidizedMinorDetailGame();
      await tester.pumpWidget(
        _detailHost(
          game: game,
          humanPlayerId: 'gp1',
          factionId: 'm1',
          factionDisplayName: 'Bavaria',
          kind: FactionKind.minor,
          boundaryKey: boundaryKey,
        ),
      );
      await _pumpBuilt(tester);

      expect(find.text('CURRENT RELATION'), findsOneWidget);
      expect(find.text(kDiplomacyChipEmbassy), findsWidgets);
      expect(
        find.text('${kDiplomacyChipOverseasPrefix}2 \u00b7 80%'),
        findsOneWidget,
      );
      expect(find.byType(RelationMeter), findsOneWidget);
      expect(find.text('Outgoing subsidy:'), findsNothing);
      expect(find.text('DOSSIER'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_detail_subsidized_minor.png'),
      );
    },
  );
}
