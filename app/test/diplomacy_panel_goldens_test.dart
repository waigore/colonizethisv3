// Widget goldens for the diplomacy surface visual acceptance criteria
// (Refs #3341 AC-14). Pixel baselines live under `app/test/goldens/` and are
// asserted with `matchesGoldenFile`, following the committed golden harness
// pattern (`new_game_leader_selection_dialog_golden_test.dart`,
// `province_build_improvement_shortcut_host_goldens_test.dart`): a keyed
// `RepaintBoundary` wraps each surface, deterministic fixtures pin the content,
// and `AppThemes.editorialMonocle` supplies the dark-theme chrome
// (`colonizethis-ui-design.mdc`).
//
// Each golden is paired with structural finder assertions so the test still
// maps to an AC even on a platform where pixel goldens are regenerated:
//
//  - AC-1  empty-state panel: three section headings + "No tribes contacted
//          yet." placeholder.
//  - AC-7  Great Power row at peace: overture stages + `Establish FTP`.
//  - AC-6  discovered Tribe row: overture stages.
//  - AC-10 disabled-not-hidden: at least one disabled `CtNinePatchButton`.
//  - AC-4  first-contact herald `OVL80001` (`TribeFirstContactOverlay`).
//  - R12/R13 colony Tribe row: Colony + Embassy standing chips, a
//          `Boycott vs Castile` chip, and the 10-step relation meter.
//  - R3/R8/R12 subsidized Minor row: `Outgoing subsidy: 10%` economic line and
//          the `Overseas: 2 · 80%` standing chip.
//
// SPEC: SPEC/ui/diplomacy-panel.md § Acceptance criteria (AC-14), § Diplomatic
// standing chip cluster acceptance criteria (Refs #3753 R12), and
// SPEC/ui/tribe-first-contact-overlay.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/tribe_first_contact_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/relation_meter.dart';

import 'support/diplomacy_panel_test_support.dart';
import 'support/golden_capture_harness.dart';
import 'support/yarn_test_fixtures.dart';

/// Minimal in-memory [AssetBundle] returning the supplied yarn text so the
/// herald golden is deterministic and offline (mirrors
/// `tribe_first_contact_overlay_test.dart`).
const MapTopology _emptyTopology = MapTopology(nodes: [], edges: []);

const Player _soloGp = Player(id: 'gp1', displayName: 'Solo', isHuman: true);
const Player _albion = Player(id: 'gp1', displayName: 'Albion', isHuman: true);
const Player _castile = Player(id: 'gp2', displayName: 'Castile', isHuman: false);
const List<Player> _albionCastile = [_albion, _castile];

Province _prov(
  String regionId,
  String localId,
  String displayName,
  String ownerId,
) =>
    Province(
      id: '$regionId|$localId',
      regionId: regionId,
      displayName: displayName,
      ownerId: ownerId,
    );

WorldState _goldenWorld({
  required int turnNumber,
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
  Map<String, String> purchasedTilesByTileKey = const {},
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
      const {},
}) {
  return WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
    oldWorld: RegionData(provinces: oldWorldProvinces, units: const []),
    newWorld: newWorldProvinces.isEmpty
        ? const RegionData()
        : RegionData(provinces: newWorldProvinces, units: const []),
    playerVisibilityByTile: playerVisibilityByTile,
    playerProspectedTiles: const {},
    purchasedTilesByTileKey: purchasedTilesByTileKey,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
  );
}

Game _goldenGame({
  required String id,
  required WorldState world,
  List<Player> players = const [_albion],
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
  List<OvertureState> overtureStates = const [],
  List<ColonyState> colonyStates = const [],
  List<BoycottState> boycottStates = const [],
  List<SubsidyState> subsidyStates = const [],
}) {
  return Game(
    id: id,
    worldState: world,
    players: players,
    tribes: tribes,
    minorNations: minorNations,
    diplomacyRelations: diplomacyRelations,
    overtureStates: overtureStates,
    colonyStates: colonyStates,
    boycottStates: boycottStates,
    subsidyStates: subsidyStates,
  );
}

WorldState _homeRivalWorld({required int turnNumber}) => _goldenWorld(
  turnNumber: turnNumber,
  oldWorldProvinces: [
    _prov('oldWorld', 'p1', 'Home', 'gp1'),
    _prov('oldWorld', 'p2', 'Rival', 'gp2'),
  ],
);

WorldState _homeTribeWorld({
  required int turnNumber,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => _goldenWorld(
  turnNumber: turnNumber,
  oldWorldProvinces: [_prov('oldWorld', 'p1', 'Home', 'gp1')],
  newWorldProvinces: [_prov('newWorld', 't1prov', 'Tribe Land', 't1')],
  playerVisibilityByTile: playerVisibilityByTile,
);

/// AC-1: solo GP, empty sections.
Game _emptyStateGame() => _goldenGame(
  id: 'diplo-golden-empty',
  world: _goldenWorld(
    turnNumber: 0,
    oldWorldProvinces: [_prov('oldWorld', 'p1', 'P1', 'gp1')],
  ),
  players: const [_soloGp],
);

/// AC-7 / AC-10: at-peace GP row with overture + FTP matrix.
Game _greatPowerRowGame() => _goldenGame(
  id: 'diplo-golden-gp',
  world: _homeRivalWorld(turnNumber: 4),
  players: _albionCastile,
  diplomacyRelations: const [
    DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2'),
  ],
);

/// AC-4 (#3625): allied GP row with ALLIANCE badge / Devoted band.
Game _alliedGreatPowerRowGame() => _goldenGame(
  id: 'diplo-golden-gp-alliance',
  world: _homeRivalWorld(turnNumber: 4),
  players: _albionCastile,
  diplomacyRelations: const [
    DiplomacyRelation(
      factionId1: 'gp1',
      factionId2: 'gp2',
      score: 90,
      formalAlliance: true,
    ),
  ],
);

/// AC-6: discovered Tribe via tile visibility, no relation.
Game _tribeRowGame() => _goldenGame(
  id: 'diplo-golden-tribe',
  world: _homeTribeWorld(
    turnNumber: 3,
    playerVisibilityByTile: const {
      'gp1': {'newWorld|t1prov|0|0': 'fullyVisible'},
    },
  ),
  tribes: const [Tribe(id: 't1', displayName: 'Powhatan')],
);

/// Refs #3753 R12/R13: colony Tribe standing chips + relation meter.
Game _colonyTribeRowGame() => _goldenGame(
  id: 'diplo-golden-colony-tribe',
  world: _homeTribeWorld(turnNumber: 6),
  players: _albionCastile,
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

/// Refs #3753 R3/R8/R12: subsidized Minor with overseas chip.
Game _subsidizedMinorRowGame() {
  const nw = 'newWorld';
  const minorProvinceId = '$nw|m1prov';
  const tileA = '$minorProvinceId|0|0';
  const tileB = '$minorProvinceId|1|0';
  return _goldenGame(
    id: 'diplo-golden-subsidized-minor',
    world: _goldenWorld(
      turnNumber: 8,
      oldWorldProvinces: [_prov('oldWorld', 'p1', 'Home', 'gp1')],
      newWorldProvinces: [
        _prov(nw, 'm1prov', 'Bavaria Coast', 'm1'),
      ],
      purchasedTilesByTileKey: const {tileA: 'gp1', tileB: 'gp1'},
      tileKeysByRegionAndProvince: const {
        nw: {
          minorProvinceId: [tileA, tileB],
        },
      },
    ),
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
  );
}

Widget _panelHost({
  required Game game,
  required Key boundaryKey,
  MapTopology topology = _emptyTopology,
  // SPEC/ui/diplomacy-panel.md § Responsive layout: default 460 dp = narrow;
  // width > kDiplomacyRowNarrowMaxWidth (500) = wide trailing cluster (#3621).
  double width = 460,
  double height = 1000,
}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    child: SizedBox(
      width: width,
      height: height,
      child: DiplomacyPanel(
        game: game,
        humanPlayerId: 'gp1',
        topology: topology,
        currentOrders: const Orders(),
        bus: AppEventBus.create(),
      ),
    ),
  );
}

Future<void> _pumpGoldenPanel(
  WidgetTester tester, {
  required Game game,
  required Key boundaryKey,
  Size surface = const Size(600, 1100),
  double width = 460,
  double height = 1000,
}) async {
  await configureGoldenSurface(tester, size: surface);
  await tester.pumpWidget(
    _panelHost(
      game: game,
      boundaryKey: boundaryKey,
      width: width,
      height: height,
    ),
  );
  await pumpDiplomacyPanelBuilt(tester);
}

Future<void> _runPanelGolden(
  WidgetTester tester, {
  required Game game,
  required String keyId,
  required String golden,
  required void Function(WidgetTester tester) pin,
  Size surface = const Size(600, 1100),
  double width = 460,
  double height = 1000,
}) async {
  final boundaryKey = ValueKey<String>(keyId);
  await _pumpGoldenPanel(
    tester,
    game: game,
    boundaryKey: boundaryKey,
    surface: surface,
    width: width,
    height: height,
  );
  pin(tester);
  await expectLater(
    find.byKey(boundaryKey),
    matchesGoldenFile(golden),
  );
}

void main() {
  suppressLogsForTests();

  setUp(AppEventBus.reset);

  for (final case_
      in <
        ({
          String name,
          Game Function() game,
          String keyId,
          String golden,
          void Function(WidgetTester tester) pin,
        })
      >[
        (
          name: 'AC-1 golden: empty-state panel shows headings + tribe placeholder',
          game: _emptyStateGame,
          keyId: 'diplomacy_empty_state_golden',
          golden: 'goldens/diplomacy_panel_empty_state.png',
          pin: (_) {
            expect(find.text('Great Powers'), findsOneWidget);
            expect(find.text('Minor Nations'), findsOneWidget);
            expect(find.text('Tribes'), findsOneWidget);
            expect(find.text('No tribes contacted yet.'), findsOneWidget);
          },
        ),
        (
          name:
              'AC-7/AC-10 golden: GP row shows overture + FTP controls, disabled stages present',
          game: _greatPowerRowGame,
          keyId: 'diplomacy_gp_row_golden',
          golden: 'goldens/diplomacy_panel_gp_row.png',
          pin: (_) {
            expect(find.text('Great Powers'), findsOneWidget);
            expect(find.text('Castile'), findsOneWidget);
            expect(find.text('Consulate'), findsWidgets);
            expect(find.text('Embassy'), findsWidgets);
            expect(find.text('Establish FTP'), findsWidgets);
            expect(
              find.byWidgetPredicate(
                (Widget w) => w is CtNinePatchButton && !w.enabled,
              ),
              findsWidgets,
            );
          },
        ),
        (
          name: 'AC-4 (#3625) golden: allied GP row shows ALLIANCE treaty badge',
          game: _alliedGreatPowerRowGame,
          keyId: 'diplomacy_gp_alliance_row_golden',
          golden: 'goldens/diplomacy_panel_gp_alliance_row.png',
          pin: (_) {
            expect(find.text('Castile'), findsOneWidget);
            expect(find.text(kDiplomacyAllianceBadgeLabel), findsOneWidget);
            expect(find.textContaining('Devoted'), findsWidgets);
            expect(find.text('Break Alliance'), findsOneWidget);
            expect(find.text('Alliance'), findsNothing);
          },
        ),
        (
          name: 'AC-6 golden: discovered Tribe row shows overture controls',
          game: _tribeRowGame,
          keyId: 'diplomacy_tribe_row_golden',
          golden: 'goldens/diplomacy_panel_tribe_row.png',
          pin: (_) {
            expect(find.text('Tribes'), findsOneWidget);
            expect(find.text('Powhatan'), findsOneWidget);
            expect(find.text('No tribes contacted yet.'), findsNothing);
            expect(find.text('Consulate'), findsWidgets);
          },
        ),
        (
          name:
              'R12/R13 golden: colony Tribe row shows standing chips + relation meter',
          game: _colonyTribeRowGame,
          keyId: 'diplomacy_colony_tribe_row_golden',
          golden: 'goldens/diplomacy_panel_colony_tribe_row.png',
          pin: (_) {
            expect(find.text('Powhatan'), findsOneWidget);
            expect(find.text(kDiplomacyChipColony), findsOneWidget);
            expect(find.text(kDiplomacyChipEmbassy), findsWidgets);
            expect(
              find.text('${kDiplomacyChipBoycottVsPrefix}Castile'),
              findsOneWidget,
            );
            expect(find.byType(RelationMeter), findsWidgets);
          },
        ),
        (
          name:
              'R3/R8/R12 golden: subsidized Minor row shows subsidy line + overseas chip',
          game: _subsidizedMinorRowGame,
          keyId: 'diplomacy_subsidized_minor_row_golden',
          golden: 'goldens/diplomacy_panel_subsidized_minor_row.png',
          pin: (_) {
            expect(find.text('Bavaria'), findsOneWidget);
            expect(find.text(kDiplomacyChipEmbassy), findsWidgets);
            expect(
              find.text('${kDiplomacyChipOverseasPrefix}2 \u00b7 80%'),
              findsOneWidget,
            );
            expect(
              find.text('Outgoing subsidy: 10% to Bavaria'),
              findsOneWidget,
            );
          },
        ),
      ]) {
    testWidgets(case_.name, (WidgetTester tester) async {
      await _runPanelGolden(
        tester,
        game: case_.game(),
        keyId: case_.keyId,
        golden: case_.golden,
        pin: case_.pin,
      );
    });
  }

  testWidgets(
    'wide GP-row golden: trailing action cluster flows left-to-right (Refs #3621)',
    (WidgetTester tester) async {
      // SPEC/ui/diplomacy-panel.md § Acceptance criteria (wide-viewport GP-row
      // golden, Refs #3621): host 800 dp (> 500 dp) uses wide trailing cluster.
      await _runPanelGolden(
        tester,
        game: _greatPowerRowGame(),
        keyId: 'diplomacy_gp_row_wide_golden',
        golden: 'goldens/diplomacy_panel_gp_row_wide.png',
        surface: const Size(1000, 1200),
        width: 800,
        height: 1200,
        pin: (tester) {
          final Key bodyKey = ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2');
          expect(find.byKey(bodyKey), findsOneWidget);
          expect(
            tester.widget(find.byKey(bodyKey)),
            isA<Row>(),
            reason:
                'Wide (> 500 dp) GP row body must be a Row per § Responsive layout.',
          );
          final Finder buttons = find.descendant(
            of: find.byKey(bodyKey),
            matching: find.byType(CtNinePatchButton),
          );
          final int count = buttons.evaluate().length;
          expect(count, greaterThanOrEqualTo(4));
          const double tol = 0.5;
          double quantize(double v) => (v / tol).roundToDouble() * tol;
          final Map<double, Set<double>> leftsByRunTop =
              <double, Set<double>>{};
          for (int i = 0; i < count; i++) {
            final Rect r = tester.getRect(buttons.at(i));
            leftsByRunTop
                .putIfAbsent(quantize(r.top), () => <double>{})
                .add(quantize(r.left));
          }
          final int largestRun = leftsByRunTop.values
              .map((Set<double> lefts) => lefts.length)
              .reduce((int a, int b) => a > b ? a : b);
          expect(
            largestRun,
            greaterThanOrEqualTo(2),
            reason:
                'Wide action cluster must place at least two buttons on one run '
                'so the cluster flows left-to-right (Refs #3621).',
          );
        },
      );
    },
  );

  testWidgets(
    'AC-4 golden: first-contact herald (OVL80001) names tribe and capital',
    (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: const Size(600, 800));
      const boundaryKey = ValueKey<String>('tribe_first_contact_herald_golden');

      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: boundaryKey,
          center: false,
          useScaffold: false,
          child: TribeFirstContactOverlay(
            tribeName: 'Powhatan',
            capitalName: 'Werowocomoco',
            assetBundle: YarnStringAssetBundle({
              kDialogueTribeFirstContactAsset: kYarnTribeFirstContactHerald,
            }),
            onDismissed: () {},
            child: const ColoredBox(color: Color(0xFF101014)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('First Contact'), findsOneWidget);
      expect(find.textContaining('Powhatan'), findsOneWidget);
      expect(find.textContaining('Werowocomoco'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_tribe_first_contact_herald.png'),
      );
    },
  );
}
