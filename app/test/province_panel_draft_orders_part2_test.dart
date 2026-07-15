// Province overlay: draft work orders and localized military labels.
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

const _regionId = 'oldWorld';
const _localProvinceId = 'pDraft';
const _localDestProvinceId = 'pDest';
const _humanId = 'gp1';
String get _fullProvinceId => '$_regionId|$_localProvinceId';
String get _fullDestProvinceId => '$_regionId|$_localDestProvinceId';
String _tileKey(int x, int y) => '$_fullProvinceId|$x|$y';

const _humanPlayer = Player(
  id: _humanId,
  displayName: 'Human',
  isHuman: true,
  treasury: 0,
);

/// Bounded pumps only — avoid [pumpAndSettle] (animations / unbounded work).
Future<void> _pumpOverlayLayout(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

Province _province({
  required String id,
  required String displayName,
  String? ownerId,
}) => Province(
  id: id,
  regionId: id.split('|').first,
  displayName: displayName,
  ownerId: ownerId,
);

RegionMapViewData _region({
  TileVisibility visibility = TileVisibility.visible,
  Set<String> greatPowerFactionIds = const {_humanId},
}) {
  return RegionMapViewData(
    regionId: _regionId,
    width: 1,
    height: 1,
    cellSize: 32,
    cells: [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: _localProvinceId,
        isSea: false,
        terrainTypeId: 'plains',
        visibility: visibility,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: greatPowerFactionIds,
    terrainColors: const {},
  );
}

PlayerView _view({
  required String tileKey,
  VisibilityLevel visibility = VisibilityLevel.fullyVisible,
  Map<String, Province> provincesById = const {},
}) {
  return PlayerView(
    playerId: _humanId,
    player: _humanPlayer,
    ownUnitsById: const {},
    provincesById: provincesById,
    visibilityByTile: {tileKey: visibility},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

Game _game({
  required String id,
  required String tileKey,
  List<Unit> units = const [],
  List<Fleet> fleets = const [],
  List<Province>? oldWorldProvinces,
  Map<String, Map<String, int>>? spyRevealTurnsByPlayer,
  List<Player> players = const [_humanPlayer],
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces:
            oldWorldProvinces ??
            [
              _province(id: _fullProvinceId, displayName: 'FromProv'),
            ],
        units: units,
      ),
      newWorld: const RegionData(),
      fleets: fleets,
      tileKeysByRegionAndProvince: {
        _regionId: {
          _fullProvinceId: [tileKey],
        },
      },
      spyRevealTurnsByPlayer: spyRevealTurnsByPlayer ?? const {},
    ),
    players: players,
  );
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required Game game,
  required String tileKey,
  required PlayerView playerView,
  Orders draftOrders = const Orders(),
  TileVisibility regionVisibility = TileVisibility.visible,
  Set<String> greatPowerFactionIds = const {_humanId},
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: ProvinceSeaZoneDetailOverlay(
          game: game,
          region: _region(
            visibility: regionVisibility,
            greatPowerFactionIds: greatPowerFactionIds,
          ),
          displayId: _fullProvinceId,
          selectedTileKey: tileKey,
          humanPlayerId: _humanId,
          playerView: playerView,
          draftOrders: draftOrders,
        ),
      ),
    ),
  );
  await _pumpOverlayLayout(tester);
}

Unit _regimentOnTile(String tileKey) => Unit(
  id: 'r_move',
  type: 'peasant_levies',
  ownerId: _humanId,
  locationProvinceId: _fullProvinceId,
  tileKey: tileKey,
  status: UnitStatus.idle,
);

Orders _pendingRegimentMove() => Orders(
  moveOrdersByPlayerId: {
    _humanId: [
      MoveOrder(
        unitId: 'r_move',
        destinationTileKey: '$_fullDestProvinceId|0|0',
      ),
    ],
  },
);

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay draft orders (military & naval)', () {
    testWidgets(
      'Military pending move falls back to raw id for unknown destination',
      (WidgetTester tester) async {
        final tk = _tileKey(0, 0);
        await _pumpOverlay(
          tester,
          game: _game(
            id: 'mil_pending_unknown_dest_test',
            tileKey: tk,
            units: [_regimentOnTile(tk)],
          ),
          tileKey: tk,
          playerView: _view(tileKey: tk),
          draftOrders: Orders(
            moveOrdersByPlayerId: {
              _humanId: [
                const MoveOrder(
                  unitId: 'r_move',
                  destinationTileKey: 'newWorld|ghostNW|0|0',
                ),
              ],
            },
          ),
        );

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
        await _pumpOverlay(
          tester,
          game: _game(
            id: 'naval_pending_test',
            tileKey: tk,
            oldWorldProvinces: [
              _province(id: _fullProvinceId, displayName: 'PortProv'),
              _province(id: _fullDestProvinceId, displayName: 'OtherPort'),
            ],
            fleets: [
              Fleet(
                id: 'fleet_in_port',
                ownerId: _humanId,
                regionId: _regionId,
                inPortAtProvinceId: _fullProvinceId,
                shipTypeIds: const ['sloop'],
              ),
            ],
          ),
          tileKey: tk,
          playerView: _view(tileKey: tk),
          draftOrders: Orders(
            navalMoveOrdersByPlayerId: {
              _humanId: [
                NavalMoveOrder(
                  fleetId: 'fleet_in_port',
                  destinationPortProvinceId: _fullDestProvinceId,
                ),
              ],
            },
            navalMissionOrdersByPlayerId: {
              _humanId: [
                const NavalMissionOrder(
                  fleetId: 'fleet_in_port',
                  mission: 'patrol',
                ),
              ],
            },
          ),
        );

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
        final foreignProvince = _province(
          id: _fullProvinceId,
          displayName: 'ForeignProv',
          ownerId: 'gp2',
        );
        await _pumpOverlay(
          tester,
          game: _game(
            id: 'intel_gate_hidden_test',
            tileKey: tk,
            oldWorldProvinces: [
              foreignProvince,
              _province(id: _fullDestProvinceId, displayName: 'DestProv'),
            ],
            units: [_regimentOnTile(tk)],
            players: const [
              _humanPlayer,
              Player(
                id: 'gp2',
                displayName: 'Foreign',
                isHuman: false,
                treasury: 0,
              ),
            ],
          ),
          tileKey: tk,
          regionVisibility: TileVisibility.fogged,
          greatPowerFactionIds: const {_humanId, 'gp2'},
          playerView: _view(
            tileKey: tk,
            visibility: VisibilityLevel.fogged,
            provincesById: {_fullProvinceId: foreignProvince},
          ),
          draftOrders: _pendingRegimentMove(),
        );

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
        final foreignProvince = _province(
          id: _fullProvinceId,
          displayName: 'ForeignProv',
          ownerId: 'gp2',
        );
        await _pumpOverlay(
          tester,
          game: _game(
            id: 'intel_gate_timer_test',
            tileKey: tk,
            oldWorldProvinces: [
              foreignProvince,
              _province(id: _fullDestProvinceId, displayName: 'DestProv'),
            ],
            units: [_regimentOnTile(tk)],
            spyRevealTurnsByPlayer: {
              _humanId: {_fullProvinceId: 3},
            },
            players: const [
              _humanPlayer,
              Player(
                id: 'gp2',
                displayName: 'Foreign',
                isHuman: false,
                treasury: 0,
              ),
            ],
          ),
          tileKey: tk,
          regionVisibility: TileVisibility.fogged,
          greatPowerFactionIds: const {_humanId, 'gp2'},
          playerView: _view(
            tileKey: tk,
            visibility: VisibilityLevel.fogged,
            provincesById: {_fullProvinceId: foreignProvince},
          ),
          draftOrders: _pendingRegimentMove(),
        );

        expect(
          find.textContaining('Ordered: move regiment to'),
          findsOneWidget,
        );
        expect(find.textContaining('DestProv'), findsOneWidget);
      },
    );
  });
}
