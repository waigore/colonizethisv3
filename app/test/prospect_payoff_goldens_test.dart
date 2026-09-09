// Pixel goldens for Prospect payoff gist variants (Refs #4741).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md § Prospect payoff gist;
// SPEC/ui/map-widget.md work-target selection.

import 'package:colonizethis_app/features/game/flame/map_area/game_map_canvas_stack_selection_prompt.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_support.dart'
    show provinceOverlayInlineActions;
import 'package:colonizethis_app/features/game/widgets/units/civilian/prospect_payoff_copy.dart';
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

const _tile = 'oldWorld|p1|0|0';

Game _game() {
  const humanId = 'gp1';
  const p1 = 'oldWorld|p1';
  return Game(
    id: 'g_prospect_payoff_golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(id: p1, regionId: 'oldWorld', ownerId: humanId),
        ],
        units: [
          Unit(
            id: 'u_explorer',
            type: kUnitTypeExplorer,
            ownerId: humanId,
            locationProvinceId: p1,
            tileKey: _tile,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          p1: [_tile],
        },
      },
      playerVisibilityByTile: {
        humanId: {_tile: 'fullyVisible'},
      },
    ),
    players: const [Player(id: humanId, displayName: 'Human', isHuman: true)],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData _region() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
    height: 1,
    cellSize: 16,
    cells: [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainType: TerrainType.hills,
        ownerFactionId: 'gp1',
        provinceDisplayName: 'Test Province',
        visibility: TileVisibility.fogged,
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

Widget _overlay(Game game) {
  return ProvinceSeaZoneDetailOverlay(
    game: game,
    region: _region(),
    displayId: 'oldWorld|p1',
    selectedTileKey: _tile,
    humanPlayerId: 'gp1',
    playerView: buildPlayerView(
      game,
      provinceShortcutHostCombinedTopology(),
      game.players.first.id,
    ),
    civilianInlineActions: provinceOverlayInlineActions(
      prospect: (showIcon: true, enabled: true, hasMatchingUnits: true),
    ),
    inlineActionCallbacks: (
      onExploreWithExplorerTap: null,
      onProspectWithExplorerTap: () {},
      onBuildImprovementTap: null,
      onBuildRoadTap: null,
      onBuildFortTap: null,
      onBuildPortTap: null,
      onBuildRailroadTap: null,
      onPurchaseLandTap: null,
      onTrainCivilianTap: null,
    ),
    onClose: () {},
  );
}

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  Future<void> pumpOverlay(
    WidgetTester tester, {
    required Key boundaryKey,
    required Size size,
    required double width,
  }) async {
    final game = _game();
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: size,
      includeLocalizations: true,
      settle: false,
      child: SizedBox(width: width, height: 680, child: _overlay(game)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(kProspectPayoffGistKey), findsOneWidget);
    expect(find.textContaining('any mineral on this tile'), findsOneWidget);
  }

  testWidgets('golden: overlay Prospect payoff 360 (Refs #4741)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('prospect_payoff_overlay_360');
    await pumpOverlay(
      tester,
      boundaryKey: boundaryKey,
      size: const Size(640, 720),
      width: 360,
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/prospect_payoff_overlay_360.png'),
    );
  });

  testWidgets('golden: overlay Prospect payoff 320 wrap (Refs #4741)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('prospect_payoff_overlay_320');
    await pumpOverlay(
      tester,
      boundaryKey: boundaryKey,
      size: const Size(640, 720),
      width: 320,
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/prospect_payoff_overlay_320.png'),
    );
  });

  testWidgets('golden: selection prompt Prospect payoff (Refs #4741)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('prospect_payoff_prompt');
    final gist = prospectPayoffGistLine(l10n: l10n, turns: 1);
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
              prospectGist: gist,
            ),
          ],
        ),
      ),
    );
    expect(find.textContaining('After this work:'), findsOneWidget);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/prospect_payoff_prompt.png'),
    );
  });
}
