// Province overlay: draft work orders and localized military labels.
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
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

  group('ProvinceSeaZoneDetailOverlay draft orders (military & naval)', () {
    testWidgets(
      'Military pending move falls back to raw id for unknown destination',
      (WidgetTester tester) async {
        final tk = _tileKey(0, 0);
        final game = Game(
          id: 'mil_pending_unknown_dest_test',
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
              const MoveOrder(
                unitId: 'r_move',
                destinationTileKey: 'newWorld|ghostNW|0|0',
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
        expect(find.textContaining('newWorld|ghostNW'), findsOneWidget);
      },
    );

    testWidgets(
      'Naval section shows pending dock move and mission from draftOrders',
      (WidgetTester tester) async {
        final tk = _tileKey(0, 0);
        final game = Game(
          id: 'naval_pending_test',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: _fullProvinceId,
                  regionId: _regionId,
                  displayName: 'PortProv',
                ),
                Province(
                  id: _fullDestProvinceId,
                  regionId: _regionId,
                  displayName: 'OtherPort',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'fleet_in_port',
                ownerId: 'gp1',
                regionId: _regionId,
                inPortAtProvinceId: _fullProvinceId,
                shipTypeIds: const ['sloop'],
              ),
            ],
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
          navalMoveOrdersByPlayerId: {
            'gp1': [
              NavalMoveOrder(
                fleetId: 'fleet_in_port',
                destinationPortProvinceId: _fullDestProvinceId,
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

        expect(find.textContaining('Ordered: dock fleet at'), findsOneWidget);
        expect(find.textContaining('OtherPort'), findsOneWidget);
        expect(
          find.textContaining('Ordered: fleet mission — patrol'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Foreign province with partial intel obfuscates sections and hides pending lines',
      (WidgetTester tester) async {
        final tk = _tileKey(0, 0);
        final game = Game(
          id: 'intel_gate_hidden_test',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: _fullProvinceId,
                  regionId: _regionId,
                  displayName: 'ForeignProv',
                  ownerId: 'gp2',
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
            Player(
              id: 'gp2',
              displayName: 'Foreign',
              isHuman: false,
              treasury: 0,
            ),
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
              visibility: TileVisibility.fogged,
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
          provincesById: {
            _fullProvinceId: Province(
              id: _fullProvinceId,
              regionId: _regionId,
              displayName: 'ForeignProv',
              ownerId: 'gp2',
            ),
          },
          visibilityByTile: {tk: VisibilityLevel.fogged},
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

        // Section headers render via CtSectionLabel (Refs #2865 S4) which
        // upper-cases the label per SPEC § Dark-theme section labels.
        expect(find.text('ECONOMIC'), findsOneWidget);
        expect(find.text('MILITARY'), findsOneWidget);
        expect(find.text('CIVILIAN'), findsOneWidget);
        expect(find.text('NAVAL'), findsOneWidget);
        expect(find.text('???'), findsNWidgets(4));
        expect(find.textContaining('Ordered: move regiment to'), findsNothing);
      },
    );

    testWidgets(
      'Spy timer bypass shows pending military lines for foreign province',
      (WidgetTester tester) async {
        final tk = _tileKey(0, 0);
        final game = Game(
          id: 'intel_gate_timer_test',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: _fullProvinceId,
                  regionId: _regionId,
                  displayName: 'ForeignProv',
                  ownerId: 'gp2',
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
            spyRevealTurnsByPlayer: {
              'gp1': {_fullProvinceId: 3},
            },
          ),
          players: const [
            Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
            Player(
              id: 'gp2',
              displayName: 'Foreign',
              isHuman: false,
              treasury: 0,
            ),
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
              visibility: TileVisibility.fogged,
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
          provincesById: {
            _fullProvinceId: Province(
              id: _fullProvinceId,
              regionId: _regionId,
              displayName: 'ForeignProv',
              ownerId: 'gp2',
            ),
          },
          visibilityByTile: {tk: VisibilityLevel.fogged},
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
  });
}
