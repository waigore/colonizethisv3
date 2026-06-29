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
//
// SPEC: SPEC/ui/diplomacy-panel.md § Acceptance criteria (AC-14) and
// SPEC/ui/tribe-first-contact-overlay.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/dialogue/tribe_first_contact_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

/// `pumpAndSettle` can hang on this surface (animated chrome keeps the ticker
/// busy); bounded pumps flush layout and the deferred build instead.
Future<void> _pumpBuilt(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

/// Minimal in-memory [AssetBundle] returning the supplied yarn text so the
/// herald golden is deterministic and offline (mirrors
/// `tribe_first_contact_overlay_test.dart`).
class _StringAssetBundle extends Fake implements AssetBundle {
  _StringAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final text = _assets[key];
    if (text == null) throw Exception('missing asset: $key');
    return text;
  }
}

const _kHeraldYarn = '''
title: tribe_first_contact
---
Scouts return from the New World with word of a people hitherto unknown to thy crown. They name themselves {\$tribeName}, and hold their seat at {\$capitalName}.
-> Continue
===
''';

const MapTopology _emptyTopology = MapTopology(nodes: [], edges: []);

/// AC-1 fixture: a solo human Great Power with no discovered factions and no
/// diplomacy relations, so every section is empty.
Game _emptyStateGame() {
  const ow = 'oldWorld';
  final p1 = Province(id: '$ow|p1', regionId: ow, displayName: 'P1', ownerId: 'gp1');
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: [p1], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  const player = Player(id: 'gp1', displayName: 'Solo', isHuman: true);
  return Game(
    id: 'diplo-golden-empty',
    worldState: world,
    players: const [player],
    diplomacyRelations: const [],
  );
}

/// AC-7 / AC-10 fixture: the human GP `gp1` holds an at-peace relation with a
/// second Great Power `gp2` (overture stage `none`), so the GP row renders the
/// full overture + `Establish FTP` matrix with the non-valid stages disabled.
Game _greatPowerRowGame() {
  const ow = 'oldWorld';
  final home = Province(id: '$ow|p1', regionId: ow, displayName: 'Home', ownerId: 'gp1');
  final rival = Province(id: '$ow|p2', regionId: ow, displayName: 'Rival', ownerId: 'gp2');
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 4),
    oldWorld: RegionData(provinces: [home, rival], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  return Game(
    id: 'diplo-golden-gp',
    worldState: world,
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2'),
    ],
  );
}

/// AC-4 (#3625) fixture: the human GP `gp1` holds a high-relation band
/// (score 90 → step 10 → "Devoted" on the 10-step ladder, Refs #3753) with GP
/// `gp2` **and** a persisted formal alliance, so the GP row renders the
/// `ALLIANCE` treaty badge on its relation line distinct from the one-word
/// relation label.
Game _alliedGreatPowerRowGame() {
  const ow = 'oldWorld';
  final home = Province(id: '$ow|p1', regionId: ow, displayName: 'Home', ownerId: 'gp1');
  final rival = Province(id: '$ow|p2', regionId: ow, displayName: 'Rival', ownerId: 'gp2');
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 4),
    oldWorld: RegionData(provinces: [home, rival], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  return Game(
    id: 'diplo-golden-gp-alliance',
    worldState: world,
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: 90,
        formalAlliance: true,
      ),
    ],
  );
}

/// AC-6 fixture: the human GP `gp1` has full tile sight into a New-World
/// province owned by Tribe `t1` but holds no relation, so the Tribe is
/// discovered via `knownDiplomaticTargetFactionIds` and renders an overture
/// matrix at first-contact standing.
Game _tribeRowGame() {
  const nw = 'newWorld';
  const ow = 'oldWorld';
  final tribeProvince = Province(id: '$nw|t1prov', regionId: nw, displayName: 'Tribe Land', ownerId: 't1');
  final home = Province(id: '$ow|p1', regionId: ow, displayName: 'Home', ownerId: 'gp1');
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
    oldWorld: RegionData(provinces: [home], units: const []),
    newWorld: RegionData(provinces: [tribeProvince], units: const []),
    playerVisibilityByTile: const {
      'gp1': {'newWorld|t1prov|0|0': 'fullyVisible'},
    },
    playerProspectedTiles: const {},
  );
  const player = Player(id: 'gp1', displayName: 'Albion', isHuman: true);
  return Game(
    id: 'diplo-golden-tribe',
    worldState: world,
    players: const [player],
    tribes: const [Tribe(id: 't1', displayName: 'Powhatan')],
    diplomacyRelations: const [],
  );
}

Widget _panelHost({
  required Game game,
  required String humanPlayerId,
  required Key boundaryKey,
  MapTopology topology = _emptyTopology,
  // SPEC/ui/diplomacy-panel.md § Responsive layout: the default 460 dp host
  // renders the narrow (≤ 500 dp) variant; a host wider than
  // `kDiplomacyRowNarrowMaxWidth` (500 dp) exercises the wide-variant
  // trailing action cluster (Refs #3621).
  double width = 460,
  double height = 1000,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: SizedBox(
            width: width,
            height: height,
            child: DiplomacyPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              topology: topology,
              currentOrders: const Orders(),
              bus: AppEventBus.create(),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  setUp(AppEventBus.reset);

  testWidgets('AC-1 golden: empty-state panel shows headings + tribe placeholder', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(600, 1100));
    const boundaryKey = ValueKey<String>('diplomacy_empty_state_golden');

    await tester.pumpWidget(
      _panelHost(
        game: _emptyStateGame(),
        humanPlayerId: 'gp1',
        boundaryKey: boundaryKey,
      ),
    );
    await _pumpBuilt(tester);

    expect(find.text('Great Powers'), findsOneWidget);
    expect(find.text('Minor Nations'), findsOneWidget);
    expect(find.text('Tribes'), findsOneWidget);
    expect(find.text('No tribes contacted yet.'), findsOneWidget);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/diplomacy_panel_empty_state.png'),
    );
  });

  testWidgets('AC-7/AC-10 golden: GP row shows overture + FTP controls, disabled stages present', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(600, 1100));
    const boundaryKey = ValueKey<String>('diplomacy_gp_row_golden');

    await tester.pumpWidget(
      _panelHost(
        game: _greatPowerRowGame(),
        humanPlayerId: 'gp1',
        boundaryKey: boundaryKey,
      ),
    );
    await _pumpBuilt(tester);

    expect(find.text('Great Powers'), findsOneWidget);
    expect(find.text('Castile'), findsOneWidget);
    expect(find.text('Consulate'), findsWidgets);
    expect(find.text('Embassy'), findsWidgets);
    expect(find.text('Establish FTP'), findsWidgets);

    // AC-10: at least one action button renders disabled rather than omitted.
    final disabledButtons = find.byWidgetPredicate(
      (Widget w) => w is CtNinePatchButton && !w.enabled,
    );
    expect(disabledButtons, findsWidgets);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/diplomacy_panel_gp_row.png'),
    );
  });

  testWidgets('AC-4 (#3625) golden: allied GP row shows ALLIANCE treaty badge', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(600, 1100));
    const boundaryKey = ValueKey<String>('diplomacy_gp_alliance_row_golden');

    await tester.pumpWidget(
      _panelHost(
        game: _alliedGreatPowerRowGame(),
        humanPlayerId: 'gp1',
        boundaryKey: boundaryKey,
      ),
    );
    await _pumpBuilt(tester);

    expect(find.text('Castile'), findsOneWidget);
    expect(find.text(kDiplomacyAllianceBadgeLabel), findsOneWidget);
    expect(find.textContaining('Devoted'), findsWidgets);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/diplomacy_panel_gp_alliance_row.png'),
    );
  });

  testWidgets(
    'wide GP-row golden: trailing action cluster flows left-to-right (Refs #3621)',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      // SPEC/ui/diplomacy-panel.md § Acceptance criteria (wide-viewport GP-row
      // golden, Refs #3621): the host panel is 800 dp wide (> 500 dp
      // kDiplomacyRowNarrowMaxWidth) so the GP row renders the wide variant
      // with the trailing compact action cluster, unlike the 460 dp narrow
      // AC-7 golden above.
      await tester.binding.setSurfaceSize(const Size(1000, 1200));
      const boundaryKey = ValueKey<String>('diplomacy_gp_row_wide_golden');

      await tester.pumpWidget(
        _panelHost(
          game: _greatPowerRowGame(),
          humanPlayerId: 'gp1',
          boundaryKey: boundaryKey,
          width: 800,
          height: 1200,
        ),
      );
      await _pumpBuilt(tester);

      // The wide variant lays the row body out as a Row (info column + trailing
      // action cluster), not the narrow Column.
      final Key bodyKey = ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2');
      expect(find.byKey(bodyKey), findsOneWidget);
      expect(
        tester.widget(find.byKey(bodyKey)),
        isA<Row>(),
        reason:
            'Wide (> 500 dp) GP row body must be a Row per § Responsive layout.',
      );

      // Rendered-geometry guard: at least one run (buttons sharing a top
      // y-offset within 0.5 dp) holds two buttons at different x-offsets, so
      // the cluster flows left-to-right rather than stacking vertically.
      final Finder buttons = find.descendant(
        of: find.byKey(bodyKey),
        matching: find.byType(CtNinePatchButton),
      );
      final int count = buttons.evaluate().length;
      expect(count, greaterThanOrEqualTo(4));
      const double tol = 0.5;
      double quantize(double v) => (v / tol).roundToDouble() * tol;
      final Map<double, Set<double>> leftsByRunTop = <double, Set<double>>{};
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

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_panel_gp_row_wide.png'),
      );
    },
  );

  testWidgets('AC-6 golden: discovered Tribe row shows overture controls', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(600, 1100));
    const boundaryKey = ValueKey<String>('diplomacy_tribe_row_golden');

    await tester.pumpWidget(
      _panelHost(
        game: _tribeRowGame(),
        humanPlayerId: 'gp1',
        boundaryKey: boundaryKey,
      ),
    );
    await _pumpBuilt(tester);

    expect(find.text('Tribes'), findsOneWidget);
    expect(find.text('Powhatan'), findsOneWidget);
    expect(find.text('No tribes contacted yet.'), findsNothing);
    expect(find.text('Consulate'), findsWidgets);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/diplomacy_panel_tribe_row.png'),
    );
  });

  testWidgets('AC-4 golden: first-contact herald (OVL80001) names tribe and capital', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(600, 800));
    const boundaryKey = ValueKey<String>('tribe_first_contact_herald_golden');

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemes.editorialMonocle,
        home: RepaintBoundary(
          key: boundaryKey,
          child: TribeFirstContactOverlay(
            tribeName: 'Powhatan',
            capitalName: 'Werowocomoco',
            assetBundle: _StringAssetBundle({
              kDialogueTribeFirstContactAsset: _kHeraldYarn,
            }),
            onDismissed: () {},
            child: const ColoredBox(color: Color(0xFF101014)),
          ),
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
  });
}
