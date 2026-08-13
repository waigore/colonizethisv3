// Visual goldens for MAP20001 Political Establish Consulate variants
// (Refs #4346). SPEC/ui/province-sea-zone-detail-overlay.md § States and
// variants.

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TerrainType;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

const String _kHumanId = 'gp1';
const String _kMinorId = 'minor1';
const String _kProvinceId = 'oldWorld|p1';
const String _kTileKey = 'oldWorld|p1|0|0';
const String _kExpertiseReason =
    'Diplomatic Expertise tech required for overtures with Minor Nations '
    'and Tribes';

class _ConsulateGoldenCase {
  const _ConsulateGoldenCase({
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

const List<_ConsulateGoldenCase> _wideCases = [
  _ConsulateGoldenCase(
    name: 'Establish Consulate enabled',
    goldenFile: 'goldens/province_establish_consulate_enabled.png',
    showControl: true,
    enabled: true,
    pending: false,
  ),
  _ConsulateGoldenCase(
    name: 'Establish Consulate disabled',
    goldenFile: 'goldens/province_establish_consulate_disabled.png',
    showControl: true,
    enabled: false,
    pending: false,
    rejectionReason: _kExpertiseReason,
  ),
  _ConsulateGoldenCase(
    name: 'Establish Consulate pending',
    goldenFile: 'goldens/province_establish_consulate_pending.png',
    showControl: true,
    enabled: true,
    pending: true,
  ),
  _ConsulateGoldenCase(
    name: 'Establish Consulate hidden',
    goldenFile: 'goldens/province_establish_consulate_hidden.png',
    showControl: false,
    enabled: false,
    pending: false,
  ),
];

Game _minorOwnedGame() {
  return Game(
    id: 'g_consulate_golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _kProvinceId,
            regionId: 'oldWorld',
            ownerId: _kMinorId,
            townTileKey: _kTileKey,
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          _kProvinceId: [_kTileKey],
        },
      },
      playerVisibilityByTile: const {
        _kHumanId: {_kTileKey: 'fullyVisible'},
      },
    ),
    players: const [Player(id: _kHumanId, displayName: 'Human', isHuman: true)],
    minorNations: const [MinorNation(id: _kMinorId, displayName: 'Bavaria')],
    tribes: const [],
  );
}

RegionMapViewData _region() {
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
        ownerFactionId: _kMinorId,
        provinceDisplayName: 'Bavaria',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: [],
    portMarkers: [],
    factionColors: {},
    greatPowerFactionIds: {_kHumanId},
    terrainColors: {},
    provincePoliticalOwnerByPrefixedProvinceId: {_kProvinceId: _kMinorId},
  );
}

Future<void> _pumpConsulateGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size surface,
  required Size overlaySize,
  required _ConsulateGoldenCase c,
}) async {
  await configureGoldenSurface(tester, size: surface);
  configureGoldenView(tester, physicalSize: surface, devicePixelRatio: 1.0);
  final game = _minorOwnedGame();
  await tester.pumpWidget(
    wrapGoldenBoundary(
      boundaryKey: boundaryKey,
      includeLocalizations: true,
      child: SizedBox(
        width: overlaySize.width,
        height: overlaySize.height,
        child: ProvinceSeaZoneDetailOverlay(
          game: game,
          region: _region(),
          displayId: _kProvinceId,
          selectedTileKey: _kTileKey,
          humanPlayerId: _kHumanId,
          playerView: buildPlayerView(game, const MapTopology(), _kHumanId),
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

void _assertConsulateControl(
  WidgetTester tester,
  _ConsulateGoldenCase c,
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

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  for (final c in _wideCases) {
    testWidgets('golden: ${c.name} (Refs #4346)', (WidgetTester tester) async {
      final boundaryKey = ValueKey<String>(
        'province_consulate_${c.name}_golden',
      );
      await _pumpConsulateGolden(
        tester,
        boundaryKey: boundaryKey,
        surface: const Size(640, 720),
        overlaySize: const Size(460, 680),
        c: c,
      );
      expect(tester.takeException(), isNull);
      final politicalHeader = find.text(
        l10n.provinceOverlay_sectionPolitical.toUpperCase(),
      );
      expect(politicalHeader, findsOneWidget);
      await tester.ensureVisible(politicalHeader);
      await tester.pump();
      _assertConsulateControl(tester, c, l10n);
      if (c.showControl) {
        final controlFinder = c.pending
            ? find.widgetWithText(
                CtActionTextButton,
                l10n.provinceOverlay_cancelEstablishConsulateAction,
              )
            : find.widgetWithText(
                CtActionTextButton,
                l10n.provinceOverlay_establishConsulateAction,
              );
        await tester.ensureVisible(controlFinder);
        await tester.pump();
      }
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    });
  }

  testWidgets(
    'golden: Establish Consulate disabled wraps at 320 dp (Refs #4346)',
    (WidgetTester tester) async {
      const c = _ConsulateGoldenCase(
        name: 'Establish Consulate disabled 320',
        goldenFile: 'goldens/province_establish_consulate_disabled_320.png',
        showControl: true,
        enabled: false,
        pending: false,
        rejectionReason: _kExpertiseReason,
      );
      const boundaryKey = ValueKey<String>('province_consulate_320_golden');
      await _pumpConsulateGolden(
        tester,
        boundaryKey: boundaryKey,
        surface: const Size(400, 640),
        overlaySize: const Size(320, 640),
        c: c,
      );
      expect(tester.takeException(), isNull);
      _assertConsulateControl(tester, c, l10n);
      expect(find.text(_kExpertiseReason), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    },
  );
}
