// Scenario table + fixtures for Establish Embassy goldens (Refs #4739).

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TerrainType;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';

import 'golden_capture_harness.dart';

const String provinceEmbassyGoldenHumanId = 'gp1';
const String provinceEmbassyGoldenMinorId = 'minor1';
const String provinceEmbassyGoldenProvinceId = 'oldWorld|p1';
const String provinceEmbassyGoldenTileKey = 'oldWorld|p1|0|0';
const String provinceEmbassyGoldenExpertiseReason =
    'Diplomatic Expertise tech required for overtures with Minor Nations '
    'and Tribes';

class ProvinceEmbassyGoldenCase {
  const ProvinceEmbassyGoldenCase({
    required this.name,
    required this.goldenFile,
    required this.showControl,
    required this.enabled,
    required this.pending,
    this.rejectionReason,
  });

  final String name;
  final String goldenFile;
  final bool showControl;
  final bool enabled;
  final bool pending;
  final String? rejectionReason;
}

const List<ProvinceEmbassyGoldenCase> provinceEmbassyWideCases = [
  ProvinceEmbassyGoldenCase(
    name: 'Establish Embassy enabled',
    goldenFile: 'goldens/province_establish_embassy_enabled.png',
    showControl: true,
    enabled: true,
    pending: false,
  ),
  ProvinceEmbassyGoldenCase(
    name: 'Establish Embassy disabled',
    goldenFile: 'goldens/province_establish_embassy_disabled.png',
    showControl: true,
    enabled: false,
    pending: false,
    rejectionReason: provinceEmbassyGoldenExpertiseReason,
  ),
  ProvinceEmbassyGoldenCase(
    name: 'Establish Embassy pending',
    goldenFile: 'goldens/province_establish_embassy_pending.png',
    showControl: true,
    enabled: true,
    pending: true,
  ),
  ProvinceEmbassyGoldenCase(
    name: 'Establish Embassy hidden',
    goldenFile: 'goldens/province_establish_embassy_hidden.png',
    showControl: false,
    enabled: false,
    pending: false,
  ),
];

Game provinceEmbassyGoldenMinorOwnedGame() {
  return Game(
    id: 'g_embassy_golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceEmbassyGoldenProvinceId,
            regionId: 'oldWorld',
            ownerId: provinceEmbassyGoldenMinorId,
            townTileKey: provinceEmbassyGoldenTileKey,
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          provinceEmbassyGoldenProvinceId: [provinceEmbassyGoldenTileKey],
        },
      },
      playerVisibilityByTile: const {
        provinceEmbassyGoldenHumanId: {
          provinceEmbassyGoldenTileKey: 'fullyVisible',
        },
      },
    ),
    players: const [
      Player(
        id: provinceEmbassyGoldenHumanId,
        displayName: 'Human',
        isHuman: true,
      ),
    ],
    minorNations: const [
      MinorNation(id: provinceEmbassyGoldenMinorId, displayName: 'Bavaria'),
    ],
    tribes: const [],
  );
}

RegionMapViewData provinceEmbassyGoldenRegion() {
  return const RegionMapViewData(
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
        ownerFactionId: provinceEmbassyGoldenMinorId,
        provinceDisplayName: 'Bavaria',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: [],
    portMarkers: [],
    factionColors: {},
    greatPowerFactionIds: {provinceEmbassyGoldenHumanId},
    terrainColors: {},
    provincePoliticalOwnerByPrefixedProvinceId: {
      provinceEmbassyGoldenProvinceId: provinceEmbassyGoldenMinorId,
    },
  );
}

Future<void> pumpProvinceEmbassyGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size surface,
  required Size overlaySize,
  required ProvinceEmbassyGoldenCase c,
}) async {
  await configureGoldenSurface(tester, size: surface);
  configureGoldenView(tester, physicalSize: surface, devicePixelRatio: 1.0);
  final game = provinceEmbassyGoldenMinorOwnedGame();
  await tester.pumpWidget(
    wrapGoldenBoundary(
      boundaryKey: boundaryKey,
      includeLocalizations: true,
      child: SizedBox(
        width: overlaySize.width,
        height: overlaySize.height,
        child: ProvinceSeaZoneDetailOverlay(
          game: game,
          region: provinceEmbassyGoldenRegion(),
          displayId: provinceEmbassyGoldenProvinceId,
          selectedTileKey: provinceEmbassyGoldenTileKey,
          humanPlayerId: provinceEmbassyGoldenHumanId,
          playerView: buildPlayerView(
            game,
            const MapTopology(),
            provinceEmbassyGoldenHumanId,
          ),
          omniscientDetail: true,
          showEstablishEmbassyControl: c.showControl,
          establishEmbassyEnabled: c.enabled,
          establishEmbassyPending: c.pending,
          establishEmbassyRejectionReason: c.rejectionReason,
          onEstablishEmbassyTap: () {},
          onClose: () {},
        ),
      ),
    ),
  );
  await pumpForGolden(tester);
}

void assertProvinceEmbassyControl(
  WidgetTester tester,
  ProvinceEmbassyGoldenCase c,
  AppLocalizationsEn l10n,
) {
  final establishFinder = find.widgetWithText(
    CtActionTextButton,
    l10n.provinceOverlay_establishEmbassyAction,
  );
  final cancelFinder = find.widgetWithText(
    CtActionTextButton,
    l10n.provinceOverlay_cancelEstablishEmbassyAction,
  );
  if (!c.showControl) {
    expect(establishFinder, findsNothing);
    expect(cancelFinder, findsNothing);
    return;
  }
  if (c.pending) {
    expect(cancelFinder, findsOneWidget);
    expect(establishFinder, findsNothing);
    final button = tester.widget<CtActionTextButton>(cancelFinder);
    expect(button.enabled, isTrue);
    expect(button.onPressed, isNotNull);
    return;
  }
  expect(establishFinder, findsOneWidget);
  final button = tester.widget<CtActionTextButton>(establishFinder);
  expect(button.enabled, c.enabled);
  expect(button.onPressed, c.enabled ? isNotNull : isNull);
}
