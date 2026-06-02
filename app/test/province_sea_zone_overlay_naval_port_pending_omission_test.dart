// Pins the "Sea-zone overlay omits port-scoped naval lines" AC for
// ProvinceSeaZoneDetailOverlay.
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
//   - § Province overlay content — Naval (sea-zone variant does not
//     forward a port province id to `provincePanelPendingNavalLines`).
//   - § Acceptance criteria — "Sea-zone overlay omits port-scoped naval
//     lines": given the overlay is in sea-zone context, when the Naval
//     section renders pending lines, then the UI layer does not append
//     any port-scoped pending naval lines regardless of `draftOrders`
//     content.
//
// Strategy: build two minimal overlays from the same world state and
// the same `draftOrders` that contain a pending `NavalMoveOrder`
// (dock-at-port) and a pending `NavalMissionOrder` for an in-port
// human-owned fleet. Render one overlay in province context (positive
// baseline — the pending lines must show, mirroring
// `province_panel_draft_orders_test.dart`) and one in sea-zone context
// (negative — the same pending lines must not show).
//
// Notes:
//   * The positive baseline guards the test setup itself: if the world
//     / orders were wrong (so the helper emitted nothing in either
//     context), the negative assertion would pass trivially. The
//     province-context render proves the orders are valid for emission
//     before pinning the sea-zone omission.
//   * The sea-zone displayId points at a revealed (non-`unrevealed`)
//     sea cell so the overlay enters the live `_seaZoneContent` branch
//     (not the obfuscated `???` fallback owned by the existing fully
//     unrevealed sea-zone AC).

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/l10n/l10n.dart';

const _regionId = 'oldWorld';
const _localPortProvinceId = 'pPort';
const _localDestPortProvinceId = 'pDest';
const _localSeaZoneId = 's0';
String get _fullPortProvinceId => '$_regionId|$_localPortProvinceId';
String get _fullDestPortProvinceId => '$_regionId|$_localDestPortProvinceId';
String get _fullSeaZoneId => '$_regionId|$_localSeaZoneId';
String _portTileKey() => '$_fullPortProvinceId|0|0';
String _seaTileKey() => '$_fullSeaZoneId|1|0';

/// Bounded pumps only — avoid `pumpAndSettle` (animations / unbounded work).
Future<void> _pumpOverlayLayout(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

Game _gameWithInPortFleet() {
  return Game(
    id: 'sea_zone_naval_omission_test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _fullPortProvinceId,
            regionId: _regionId,
            displayName: 'PortProv',
            ownerId: 'gp1',
          ),
          Province(
            id: _fullDestPortProvinceId,
            regionId: _regionId,
            displayName: 'DestPort',
            ownerId: 'gp1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: 'fleet_in_port',
          ownerId: 'gp1',
          regionId: _regionId,
          inPortAtProvinceId: _fullPortProvinceId,
          shipTypeIds: const ['sloop'],
        ),
      ],
      tileKeysByRegionAndProvince: {
        _regionId: {
          _fullPortProvinceId: [_portTileKey()],
        },
      },
      seaZoneDisplayNameById: const {'$_regionId|$_localSeaZoneId': 'North Atlantic'},
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
    ],
  );
}

RegionMapViewData _regionWithPortAndRevealedSea() {
  return RegionMapViewData(
    regionId: _regionId,
    width: 2,
    height: 1,
    cellSize: 32,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: _localPortProvinceId,
        isSea: false,
        terrainTypeId: 'plains',
        visibility: TileVisibility.visible,
      ),
      CellViewData(
        x: 1,
        y: 0,
        regionCellId: _localSeaZoneId,
        isSea: true,
        terrainTypeId: 'ocean',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {'gp1'},
    terrainColors: const {},
  );
}

PlayerView _humanPlayerView() {
  return PlayerView(
    playerId: 'gp1',
    player: const Player(
      id: 'gp1',
      displayName: 'Human',
      isHuman: true,
      treasury: 0,
    ),
    ownUnitsById: const {},
    provincesById: const {},
    visibilityByTile: {
      _portTileKey(): VisibilityLevel.fullyVisible,
      _seaTileKey(): VisibilityLevel.fullyVisible,
    },
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

Orders _pendingDockAndMissionOrders() {
  return Orders(
    navalMoveOrdersByPlayerId: {
      'gp1': [
        NavalMoveOrder(
          fleetId: 'fleet_in_port',
          destinationPortProvinceId: _fullDestPortProvinceId,
        ),
      ],
    },
    navalMissionOrdersByPlayerId: {
      'gp1': [
        const NavalMissionOrder(
          fleetId: 'fleet_in_port',
          mission: 'patrol',
        ),
      ],
    },
  );
}

Widget _wrapOverlay({
  required Game game,
  required RegionMapViewData region,
  required String displayId,
  required String? selectedTileKey,
  required PlayerView view,
  required Orders orders,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: region,
        displayId: displayId,
        selectedTileKey: selectedTileKey,
        humanPlayerId: 'gp1',
        playerView: view,
        draftOrders: orders,
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay — sea-zone naval port-pending omission',
      () {
    testWidgets(
      'Province context: pending dock + mission lines render (baseline)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrapOverlay(
            game: _gameWithInPortFleet(),
            region: _regionWithPortAndRevealedSea(),
            displayId: _fullPortProvinceId,
            selectedTileKey: _portTileKey(),
            view: _humanPlayerView(),
            orders: _pendingDockAndMissionOrders(),
          ),
        );
        await _pumpOverlayLayout(tester);

        // Positive baseline — both pending preview lines must show in
        // province context to prove `_pendingDockAndMissionOrders` is
        // valid for emission via `provincePanelPendingNavalLines`.
        expect(
          find.textContaining('Ordered: dock fleet at'),
          findsOneWidget,
          reason:
              'Province-context overlay must surface the pending dock '
              'order so the sea-zone negative assertion below is non-vacuous.',
        );
        expect(find.textContaining('DestPort'), findsOneWidget);
        expect(
          find.textContaining('Ordered: fleet mission'),
          findsOneWidget,
          reason:
              'Province-context overlay must surface the pending naval '
              'mission so the sea-zone negative assertion below is non-vacuous.',
        );
      },
    );

    testWidgets(
      'Sea-zone context: pending dock + mission lines are omitted regardless of draftOrders',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrapOverlay(
            game: _gameWithInPortFleet(),
            region: _regionWithPortAndRevealedSea(),
            // Sea-zone displayId; sea cell at (1, 0) is revealed so the
            // overlay enters the live `_seaZoneContent` branch (not the
            // fully-unrevealed `???` fallback).
            displayId: _fullSeaZoneId,
            selectedTileKey: _seaTileKey(),
            view: _humanPlayerView(),
            orders: _pendingDockAndMissionOrders(),
          ),
        );
        await _pumpOverlayLayout(tester);

        // Sanity: live sea-zone Political body rendered (sea-zone
        // display name from world state). This pins the assertion to
        // the live branch, not the obfuscated `???` fallback.
        expect(find.textContaining('North Atlantic'), findsOneWidget);

        // Negative AC: the sea-zone overlay must not emit any
        // port-scoped pending naval preview line, even though
        // `draftOrders` contains a `NavalMoveOrder` (dock) and a
        // `NavalMissionOrder` for an in-port human-owned fleet.
        expect(
          find.textContaining('Ordered: dock fleet at'),
          findsNothing,
          reason:
              'Sea-zone overlay must not append the pending dock line; '
              '`pendingNavalPortProvinceId` should be null in sea-zone context '
              'per SPEC § Province overlay content — Naval.',
        );
        expect(find.textContaining('DestPort'), findsNothing);
        expect(
          find.textContaining('Ordered: fleet mission'),
          findsNothing,
          reason:
              'Sea-zone overlay must not append the pending naval mission '
              'line; `pendingNavalPortProvinceId` should be null in sea-zone '
              'context per SPEC § Province overlay content — Naval.',
        );
      },
    );
  });
}
