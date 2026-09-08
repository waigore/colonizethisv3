// Pixel goldens for Upgrade town workshop payoff (Refs #4747).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md; SPEC/ui/map-widget.md.

import 'package:colonizethis_app/features/game/flame/map_area/game_map_canvas_stack_selection_prompt.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/upgrade_town_payoff_copy.dart';
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

Game _game({required int townLevel}) {
  const humanId = 'gp1';
  const p1 = 'oldWorld|p1';
  return Game(
    id: 'g_upgrade_town_payoff_golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: p1,
            regionId: 'oldWorld',
            ownerId: humanId,
            townDevelopmentLevel: townLevel,
            townTileKey: _tile,
          ),
        ],
        units: [
          Unit(
            id: 'u_builder',
            type: kUnitTypeBuilder,
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
        terrainType: TerrainType.plains,
        ownerFactionId: 'gp1',
        provinceDisplayName: 'Test Province',
        visibility: TileVisibility.visible,
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

Widget _overlay(Game game, {required bool enabled}) {
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
    showUpgradeTownControl: true,
    upgradeTownEnabled: enabled,
    upgradeTownHasBuilderUnits: enabled,
    upgradeTownTargetTileKey: _tile,
    onUpgradeTownTap: () {},
    onClose: () {},
  );
}

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  testWidgets('golden: overlay 2→3 pause 360 (Refs #4747)', (tester) async {
    const boundaryKey = ValueKey<String>('upgrade_town_pause_360');
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(640, 720),
      includeLocalizations: true,
      settle: false,
      child: SizedBox(
        width: 360,
        height: 680,
        child: _overlay(_game(townLevel: 2), enabled: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(kUpgradeTownPayoffGistKey), findsOneWidget);
    expect(find.textContaining('pause until level 4'), findsOneWidget);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/upgrade_town_payoff_pause_360.png'),
    );
  });

  testWidgets('golden: overlay 2→3 pause 320 wrap (Refs #4747)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>('upgrade_town_pause_320');
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(640, 720),
      includeLocalizations: true,
      settle: false,
      child: SizedBox(
        width: 320,
        height: 680,
        child: _overlay(_game(townLevel: 2), enabled: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/upgrade_town_payoff_pause_320.png'),
    );
  });

  testWidgets('golden: selection prompt + pending gist (Refs #4747)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>('upgrade_town_prompt_pending');
    final gist = upgradeTownPayoffGistLine(l10n: l10n, fromLevel: 2, turns: 1);
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(640, 280),
      includeLocalizations: true,
      useScaffold: false,
      center: false,
      settle: false,
      child: SizedBox(
        width: 640,
        height: 280,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GameMapCanvasStackSelectionPrompt(
              isNarrow: false,
              overlayOpen: false,
              onCancel: () {},
              upgradeTownGist: gist,
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: UpgradeTownPayoffGistLine(text: gist),
            ),
          ],
        ),
      ),
    );
    expect(find.textContaining('After this work:'), findsWidgets);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/upgrade_town_payoff_prompt_pending.png'),
    );
  });

  testWidgets('disabled Upgrade town hides assign gist (Refs #4747)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>('upgrade_town_disabled');
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(640, 720),
      includeLocalizations: true,
      settle: false,
      child: SizedBox(
        width: 360,
        height: 680,
        child: _overlay(_game(townLevel: 2), enabled: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(kUpgradeTownPayoffGistKey), findsNothing);
    expect(find.textContaining('Town workshops are active'), findsOneWidget);
  });
}
