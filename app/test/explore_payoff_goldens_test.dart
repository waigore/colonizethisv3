// Pixel goldens for Explore payoff gist variants (Refs #4733).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md § Explore payoff gist;
// SPEC/ui/map-widget.md work-target selection.

import 'package:colonizethis_app/features/game/flame/map_area/game_map_canvas_stack_selection_prompt.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_support.dart'
    show provinceOverlayInlineActions;
import 'package:colonizethis_app/features/game/widgets/units/civilian/explore_payoff_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/explore_payoff_gist_line.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'province_shortcut_host_emit_fixtures.dart'
    show provinceShortcutHostCombinedTopology;

class _ExplorePayoffGoldenCase {
  const _ExplorePayoffGoldenCase({
    required this.slug,
    required this.targetTiles,
    required this.otherTiles,
    required this.turns,
  });

  final String slug;
  final List<String> targetTiles;
  final List<String> otherTiles;
  final int turns;
}

const _cases = <_ExplorePayoffGoldenCase>[
  _ExplorePayoffGoldenCase(
    slug: 'one_turn',
    targetTiles: ['oldWorld|p1|0|0'],
    otherTiles: ['oldWorld|p2|0|0', 'oldWorld|p2|1|0', 'oldWorld|p2|2|0'],
    turns: 1,
  ),
  _ExplorePayoffGoldenCase(
    slug: 'three_turns',
    targetTiles: [
      'oldWorld|p1|0|0',
      'oldWorld|p1|1|0',
      'oldWorld|p1|2|0',
    ],
    otherTiles: ['oldWorld|p2|0|0'],
    turns: 3,
  ),
];

Game _gameFor(List<String> targetTiles, List<String> otherTiles) {
  const humanId = 'gp1';
  const p1 = 'oldWorld|p1';
  const p2 = 'oldWorld|p2';
  return Game(
    id: 'g_explore_payoff_golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(id: p1, regionId: 'oldWorld', ownerId: humanId),
          Province(id: p2, regionId: 'oldWorld', ownerId: humanId),
        ],
        units: [
          Unit(
            id: 'u_explorer',
            type: kUnitTypeExplorer,
            ownerId: humanId,
            locationProvinceId: p1,
            tileKey: targetTiles.first,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: {
        'oldWorld': {p1: targetTiles, p2: otherTiles},
      },
      playerVisibilityByTile: {
        humanId: {
          for (final t in targetTiles) t: 'fullyVisible',
          // Keep province partially revealed for Explore enablement semantics.
          if (targetTiles.length > 1) targetTiles.last: 'unknown',
        },
      },
    ),
    players: const [
      Player(id: humanId, displayName: 'Human', isHuman: true),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData _regionFor(Game game) {
  final tiles =
      game.worldState.tileKeysByRegionAndProvince['oldWorld']!['oldWorld|p1']!;
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: tiles.length,
    height: 1,
    cellSize: 16,
    cells: [
      for (var i = 0; i < tiles.length; i++)
        CellViewData(
          x: i,
          y: 0,
          regionCellId: 'p1',
          isSea: false,
          terrainType: TerrainType.plains,
          resourceId: 'grain',
          ownerFactionId: 'gp1',
          provinceDisplayName: 'Test Province',
          visibility: i == 0
              ? TileVisibility.fogged
              : TileVisibility.unrevealed,
        ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {'gp1'},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {'oldWorld|p1': 'gp1'},
  );
}

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  for (final c in _cases) {
    testWidgets('golden: overlay Explore payoff ${c.slug} (Refs #4733)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('explore_payoff_overlay');
      final game = _gameFor(c.targetTiles, c.otherTiles);
      final playerView = buildPlayerView(
        game,
        provinceShortcutHostCombinedTopology(),
        game.players.first.id,
      );
      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(640, 720),
        includeLocalizations: true,
        settle: false,
        child: SizedBox(
          width: 360,
          height: 680,
          child: ProvinceSeaZoneDetailOverlay(
            game: game,
            region: _regionFor(game),
            displayId: 'oldWorld|p1',
            selectedTileKey: c.targetTiles.first,
            humanPlayerId: 'gp1',
            playerView: playerView,
            civilianInlineActions: provinceOverlayInlineActions(
              explore: (
                showIcon: true,
                enabled: true,
                hasMatchingUnits: true,
              ),
            ),
            inlineActionCallbacks: (
              onExploreWithExplorerTap: () {},
              onProspectWithExplorerTap: null,
              onBuildImprovementTap: null,
              onBuildRoadTap: null,
              onBuildFortTap: null,
              onBuildPortTap: null,
              onBuildRailroadTap: null,
              onPurchaseLandTap: null,
            ),
            onClose: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(kExplorePayoffGistKey), findsOneWidget);
      expect(
        find.textContaining('this whole province becomes fully visible'),
        findsOneWidget,
      );
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/explore_payoff_overlay_${c.slug}.png'),
      );
    });

    testWidgets('golden: selection prompt Explore payoff ${c.slug} (Refs #4733)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('explore_payoff_prompt');
      final gist = explorePayoffGistLine(l10n: l10n, turns: c.turns);
      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(640, 220),
        includeLocalizations: true,
        useScaffold: false,
        center: false,
        settle: false,
        child: SizedBox(
          width: 640,
          height: 220,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GameMapCanvasStackSelectionPrompt(
                isNarrow: false,
                overlayOpen: false,
                onCancel: () {},
                exploreGist: gist,
              ),
            ],
          ),
        ),
      );
      expect(find.textContaining('After this work:'), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/explore_payoff_prompt_${c.slug}.png'),
      );
    });
  }
}
