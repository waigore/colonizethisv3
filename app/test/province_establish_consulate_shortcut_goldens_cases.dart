// Scenario table + fixtures for Establish Consulate goldens (Refs #4346).

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

const String provinceConsulateGoldenHumanId = 'gp1';
const String provinceConsulateGoldenMinorId = 'minor1';
const String provinceConsulateGoldenProvinceId = 'oldWorld|p1';
const String provinceConsulateGoldenTileKey = 'oldWorld|p1|0|0';
const String provinceConsulateGoldenExpertiseReason =
    'Diplomatic Expertise tech required for overtures with Minor Nations '
    'and Tribes';

class ProvinceConsulateGoldenCase {
  const ProvinceConsulateGoldenCase({
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

const List<ProvinceConsulateGoldenCase> provinceConsulateWideCases = [
  ProvinceConsulateGoldenCase(
    name: 'Establish Consulate enabled',
    goldenFile: 'goldens/province_establish_consulate_enabled.png',
    showControl: true,
    enabled: true,
    pending: false,
  ),
  ProvinceConsulateGoldenCase(
    name: 'Establish Consulate disabled',
    goldenFile: 'goldens/province_establish_consulate_disabled.png',
    showControl: true,
    enabled: false,
    pending: false,
    rejectionReason: provinceConsulateGoldenExpertiseReason,
  ),
  ProvinceConsulateGoldenCase(
    name: 'Establish Consulate pending',
    goldenFile: 'goldens/province_establish_consulate_pending.png',
    showControl: true,
    enabled: true,
    pending: true,
  ),
  ProvinceConsulateGoldenCase(
    name: 'Establish Consulate hidden',
    goldenFile: 'goldens/province_establish_consulate_hidden.png',
    showControl: false,
    enabled: false,
    pending: false,
  ),
];

Game provinceConsulateGoldenMinorOwnedGame() {
  return Game(
    id: 'g_consulate_golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceConsulateGoldenProvinceId,
            regionId: 'oldWorld',
            ownerId: provinceConsulateGoldenMinorId,
            townTileKey: provinceConsulateGoldenTileKey,
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          provinceConsulateGoldenProvinceId: [provinceConsulateGoldenTileKey],
        },
      },
      playerVisibilityByTile: const {
        provinceConsulateGoldenHumanId: {
          provinceConsulateGoldenTileKey: 'fullyVisible',
        },
      },
    ),
    players: const [
      Player(id: provinceConsulateGoldenHumanId, displayName: 'Human', isHuman: true),
    ],
    minorNations: const [
      MinorNation(id: provinceConsulateGoldenMinorId, displayName: 'Bavaria'),
    ],
    tribes: const [],
  );
}

RegionMapViewData provinceConsulateGoldenRegion() {
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
        ownerFactionId: provinceConsulateGoldenMinorId,
        provinceDisplayName: 'Bavaria',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: [],
    portMarkers: [],
    factionColors: {},
    greatPowerFactionIds: {provinceConsulateGoldenHumanId},
    terrainColors: {},
    provincePoliticalOwnerByPrefixedProvinceId: {
      provinceConsulateGoldenProvinceId: provinceConsulateGoldenMinorId,
    },
  );
}

Future<void> pumpProvinceConsulateGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size surface,
  required Size overlaySize,
  required ProvinceConsulateGoldenCase c,
}) async {
  await configureGoldenSurface(tester, size: surface);
  configureGoldenView(tester, physicalSize: surface, devicePixelRatio: 1.0);
  final game = provinceConsulateGoldenMinorOwnedGame();
  await tester.pumpWidget(
    wrapGoldenBoundary(
      boundaryKey: boundaryKey,
      includeLocalizations: true,
      child: SizedBox(
        width: overlaySize.width,
        height: overlaySize.height,
        child: ProvinceSeaZoneDetailOverlay(
          game: game,
          region: provinceConsulateGoldenRegion(),
          displayId: provinceConsulateGoldenProvinceId,
          selectedTileKey: provinceConsulateGoldenTileKey,
          humanPlayerId: provinceConsulateGoldenHumanId,
          playerView: buildPlayerView(
            game,
            const MapTopology(),
            provinceConsulateGoldenHumanId,
          ),
          omniscientDetail: true,
          showEstablishConsulateControl: c.showControl,
          establishConsulateEnabled: c.enabled,
          establishConsulatePending: c.pending,
          establishConsulateRejectionReason: c.rejectionReason,
          onEstablishConsulateTap: () {},
          onClose: () {},
        ),
      ),
    ),
  );
  await pumpForGolden(tester);
}

void assertProvinceConsulateControl(
  WidgetTester tester,
  ProvinceConsulateGoldenCase c,
  AppLocalizationsEn l10n,
) {
  final establishFinder = find.widgetWithText(
    CtActionTextButton,
    l10n.provinceOverlay_establishConsulateAction,
  );
  final cancelFinder = find.widgetWithText(
    CtActionTextButton,
    l10n.provinceOverlay_cancelEstablishConsulateAction,
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
