// Province overlay: draft work orders and localized military labels.
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel, kWorkTargetBuildImprovement;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/l10n/l10n.dart';

const _regionId = 'oldWorld';
const _localProvinceId = 'pDraft';
const _localDestProvinceId = 'pDest';
String get _fullProvinceId => '$_regionId|$_localProvinceId';
String get _fullDestProvinceId => '$_regionId|$_localDestProvinceId';
String _tileKey(int x, int y) => '$_fullProvinceId|$x|$y';

/// Bounded pumps only — avoid [pumpAndSettle] (animations / unbounded work).
Future<void> _pumpOverlayLayout(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay draft orders', () {
    testWidgets('Civilian line shows pending work order target, not idle', (
      WidgetTester tester,
    ) async {
      final tk = _tileKey(0, 0);
      final game = Game(
        id: 'draft_order_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: _fullProvinceId,
                regionId: _regionId,
                displayName: 'DraftProv',
              ),
            ],
            units: [
              Unit(
                id: 'u_builder',
                type: kUnitTypeBuilder,
                ownerId: 'gp1',
                locationProvinceId: _fullProvinceId,
                tileKey: tk,
                status: UnitStatus.idle,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            _regionId: {
              _fullProvinceId: [tk],
            },
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );
      final region = RegionMapViewData(
        regionId: _regionId,
        width: 1,
        height: 1,
        cellSize: 32,
        cells: const [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: _localProvinceId,
            isSea: false,
            terrainTypeId: 'plains',
            visibility: TileVisibility.visible,
          ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        factionColors: const {},
        greatPowerFactionIds: const {'gp1'},
        terrainColors: const {},
      );
      final view = PlayerView(
        playerId: 'gp1',
        player: const Player(
          id: 'gp1',
          displayName: 'Human',
          isHuman: true,
          treasury: 0,
        ),
        ownUnitsById: const {},
        provincesById: const {},
        visibilityByTile: {tk: VisibilityLevel.fullyVisible},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'gp1': [
            WorkOrder(
              unitId: 'u_builder',
              target: kWorkTargetBuildImprovement,
              targetTileKey: tk,
            ),
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: tk,
              humanPlayerId: 'gp1',
              playerView: view,
              draftOrders: orders,
            ),
          ),
        ),
      );
      await _pumpOverlayLayout(tester);

      expect(find.textContaining('build improvement'), findsOneWidget);
      expect(find.textContaining(': idle'), findsNothing);
      expect(find.textContaining('u_builder'), findsNothing);
      expect(find.text('Builder: build improvement'), findsOneWidget);
    });

    testWidgets('Civilian section omits internal unit id from display lines', (
      WidgetTester tester,
    ) async {
      final tk = _tileKey(0, 0);
      final game = Game(
        id: 'civilian_id_hidden_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: _fullProvinceId,
                regionId: _regionId,
                displayName: 'DraftProv',
              ),
            ],
            units: [
              Unit(
                id: 'gp1_explorer_1',
                type: kUnitTypeExplorer,
                ownerId: 'gp1',
                locationProvinceId: _fullProvinceId,
                tileKey: tk,
                status: UnitStatus.idle,
              ),
              Unit(
                id: 'gp2_explorer_9',
                type: kUnitTypeExplorer,
                ownerId: 'gp2',
                locationProvinceId: _fullProvinceId,
                tileKey: tk,
                status: UnitStatus.idle,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            _regionId: {
              _fullProvinceId: [tk],
            },
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
          Player(id: 'gp2', displayName: 'France', isHuman: false, treasury: 0),
        ],
      );
      final region = RegionMapViewData(
        regionId: _regionId,
        width: 1,
        height: 1,
        cellSize: 32,
        cells: const [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: _localProvinceId,
            isSea: false,
            terrainTypeId: 'plains',
            visibility: TileVisibility.visible,
          ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        factionColors: const {},
        greatPowerFactionIds: const {'gp1', 'gp2'},
        terrainColors: const {},
      );
      final view = PlayerView(
        playerId: 'gp1',
        player: const Player(
          id: 'gp1',
          displayName: 'Human',
          isHuman: true,
          treasury: 0,
        ),
        ownUnitsById: const {},
        provincesById: const {},
        visibilityByTile: {tk: VisibilityLevel.fullyVisible},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: tk,
              humanPlayerId: 'gp1',
              playerView: view,
            ),
          ),
        ),
      );
      await _pumpOverlayLayout(tester);

      expect(find.text('Explorer: idle'), findsOneWidget);
      expect(find.text('France — Explorer: idle'), findsOneWidget);
      expect(find.textContaining('gp1_explorer_1'), findsNothing);
      expect(find.textContaining('gp2_explorer_9'), findsNothing);
    });

    testWidgets('Military section uses localized regiment name', (
      WidgetTester tester,
    ) async {
      final tk = _tileKey(0, 0);
      final game = Game(
        id: 'mil_label_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: _fullProvinceId,
                regionId: _regionId,
                displayName: 'MilProv',
              ),
            ],
            units: [
              Unit(
                id: 'r1',
                type: 'peasant_levies',
                ownerId: 'gp1',
                locationProvinceId: _fullProvinceId,
                status: UnitStatus.idle,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            _regionId: {
              _fullProvinceId: [tk],
            },
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );
      final region = RegionMapViewData(
        regionId: _regionId,
        width: 1,
        height: 1,
        cellSize: 32,
        cells: const [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: _localProvinceId,
            isSea: false,
            terrainTypeId: 'plains',
            visibility: TileVisibility.visible,
          ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        factionColors: const {},
        greatPowerFactionIds: const {'gp1'},
        terrainColors: const {},
      );
      final view = PlayerView(
        playerId: 'gp1',
        player: const Player(
          id: 'gp1',
          displayName: 'Human',
          isHuman: true,
          treasury: 0,
        ),
        ownUnitsById: const {},
        provincesById: const {},
        visibilityByTile: {tk: VisibilityLevel.fullyVisible},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: tk,
              humanPlayerId: 'gp1',
              playerView: view,
            ),
          ),
        ),
      );
      await _pumpOverlayLayout(tester);

      expect(find.textContaining('Peasant levies'), findsOneWidget);
      expect(find.textContaining('peasant_levies:'), findsNothing);
    });

    testWidgets(
      'Military section shows pending regiment move line from draftOrders',
      (WidgetTester tester) async {
        final tk = _tileKey(0, 0);
        final game = Game(
          id: 'mil_pending_test',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: _fullProvinceId,
                  regionId: _regionId,
                  displayName: 'FromProv',
                ),
                Province(
                  id: _fullDestProvinceId,
                  regionId: _regionId,
                  displayName: 'DestProv',
                ),
              ],
              units: [
                Unit(
                  id: 'r_move',
                  type: 'peasant_levies',
                  ownerId: 'gp1',
                  locationProvinceId: _fullProvinceId,
                  tileKey: tk,
                  status: UnitStatus.idle,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              _regionId: {
                _fullProvinceId: [tk],
              },
            },
          ),
          players: const [
            Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
          ],
        );
        final region = RegionMapViewData(
          regionId: _regionId,
          width: 1,
          height: 1,
          cellSize: 32,
          cells: const [
            CellViewData(
              x: 0,
              y: 0,
              regionCellId: _localProvinceId,
              isSea: false,
              terrainTypeId: 'plains',
              visibility: TileVisibility.visible,
            ),
          ],
          capitalMarkers: const [],
          portMarkers: const [],
          factionColors: const {},
          greatPowerFactionIds: const {'gp1'},
          terrainColors: const {},
        );
        final view = PlayerView(
          playerId: 'gp1',
          player: const Player(
            id: 'gp1',
            displayName: 'Human',
            isHuman: true,
            treasury: 0,
          ),
          ownUnitsById: const {},
          provincesById: const {},
          visibilityByTile: {tk: VisibilityLevel.fullyVisible},
          prospectedTiles: const {},
          diplomacyByOtherId: const {},
        );
        final orders = Orders(
          moveOrdersByPlayerId: {
            'gp1': [
              MoveOrder(
                unitId: 'r_move',
                destinationTileKey: '$_fullDestProvinceId|0|0',
              ),
            ],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: game,
                region: region,
                displayId: _fullProvinceId,
                selectedTileKey: tk,
                humanPlayerId: 'gp1',
                playerView: view,
                draftOrders: orders,
              ),
            ),
          ),
        );
        await _pumpOverlayLayout(tester);

        expect(
          find.textContaining('Ordered: move regiment to'),
          findsOneWidget,
        );
        expect(find.textContaining('DestProv'), findsOneWidget);
      },
    );

    // Refs #3658: destination province label resolution migrated from a
    // hand-rolled dual-region scan to the cached cross-region
    // `WorldState.allProvincesById`. These two cases prove the migrated lookup
    // still resolves a *new-world* destination (positive) and degrades to the
    // raw id for an unknown destination (negative).
    testWidgets(
      'Military pending move resolves a new-world destination province name',
      (WidgetTester tester) async {
        const newWorldDestId = 'newWorld|pDestNW';
        final tk = _tileKey(0, 0);
        final game = Game(
          id: 'mil_pending_cross_region_test',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: _fullProvinceId,
                  regionId: _regionId,
                  displayName: 'FromProv',
                ),
              ],
              units: [
                Unit(
                  id: 'r_move',
                  type: 'peasant_levies',
                  ownerId: 'gp1',
                  locationProvinceId: _fullProvinceId,
                  tileKey: tk,
                  status: UnitStatus.idle,
                ),
              ],
            ),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: 'newWorld|pDestNW',
                  regionId: 'newWorld',
                  displayName: 'NewWorldDest',
                ),
              ],
            ),
            tileKeysByRegionAndProvince: {
              _regionId: {
                _fullProvinceId: [tk],
              },
            },
          ),
          players: const [
            Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
          ],
        );
        final region = RegionMapViewData(
          regionId: _regionId,
          width: 1,
          height: 1,
          cellSize: 32,
          cells: const [
            CellViewData(
              x: 0,
              y: 0,
              regionCellId: _localProvinceId,
              isSea: false,
              terrainTypeId: 'plains',
              visibility: TileVisibility.visible,
            ),
          ],
          capitalMarkers: const [],
          portMarkers: const [],
          factionColors: const {},
          greatPowerFactionIds: const {'gp1'},
          terrainColors: const {},
        );
        final view = PlayerView(
          playerId: 'gp1',
          player: const Player(
            id: 'gp1',
            displayName: 'Human',
            isHuman: true,
            treasury: 0,
          ),
          ownUnitsById: const {},
          provincesById: const {},
          visibilityByTile: {tk: VisibilityLevel.fullyVisible},
          prospectedTiles: const {},
          diplomacyByOtherId: const {},
        );
        final orders = Orders(
          moveOrdersByPlayerId: {
            'gp1': [
              const MoveOrder(
                unitId: 'r_move',
                destinationTileKey: '$newWorldDestId|0|0',
              ),
            ],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: game,
                region: region,
                displayId: _fullProvinceId,
                selectedTileKey: tk,
                humanPlayerId: 'gp1',
                playerView: view,
                draftOrders: orders,
              ),
            ),
          ),
        );
        await _pumpOverlayLayout(tester);

        expect(
          find.textContaining('Ordered: move regiment to'),
          findsOneWidget,
        );
        expect(find.textContaining('NewWorldDest'), findsOneWidget);
      },
    );
  });
}
