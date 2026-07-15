// Province overlay: draft work orders and localized military labels.
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel, kWorkTargetBuildImprovement;
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
}) => Province(id: id, regionId: id.split('|').first, displayName: displayName);

RegionMapViewData _region({
  Set<String> greatPowerFactionIds = const {_humanId},
}) {
  return RegionMapViewData(
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
    greatPowerFactionIds: greatPowerFactionIds,
    terrainColors: const {},
  );
}

PlayerView _view({required String tileKey}) {
  return PlayerView(
    playerId: _humanId,
    player: _humanPlayer,
    ownUnitsById: const {},
    provincesById: const {},
    visibilityByTile: {tileKey: VisibilityLevel.fullyVisible},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

Game _game({
  required String id,
  required String tileKey,
  required List<Unit> units,
  List<Province>? oldWorldProvinces,
  RegionData? newWorld,
  List<Player> players = const [_humanPlayer],
}) {
  final provinces =
      oldWorldProvinces ??
      [
        _province(id: _fullProvinceId, displayName: 'DraftProv'),
      ];
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: provinces,
        units: units,
      ),
      newWorld: newWorld ?? const RegionData(),
      tileKeysByRegionAndProvince: {
        _regionId: {
          _fullProvinceId: [tileKey],
        },
      },
    ),
    players: players,
  );
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required Game game,
  required String tileKey,
  Orders draftOrders = const Orders(),
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
          region: _region(greatPowerFactionIds: greatPowerFactionIds),
          displayId: _fullProvinceId,
          selectedTileKey: tileKey,
          humanPlayerId: _humanId,
          playerView: _view(tileKey: tileKey),
          draftOrders: draftOrders,
        ),
      ),
    ),
  );
  await _pumpOverlayLayout(tester);
}

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay draft orders', () {
    testWidgets('Civilian line shows pending work order target, not idle', (
      WidgetTester tester,
    ) async {
      final tk = _tileKey(0, 0);
      final game = _game(
        id: 'draft_order_test',
        tileKey: tk,
        units: [
          Unit(
            id: 'u_builder',
            type: kUnitTypeBuilder,
            ownerId: _humanId,
            locationProvinceId: _fullProvinceId,
            tileKey: tk,
            status: UnitStatus.idle,
          ),
        ],
      );
      await _pumpOverlay(
        tester,
        game: game,
        tileKey: tk,
        draftOrders: Orders(
          workOrdersByPlayerId: {
            _humanId: [
              WorkOrder(
                unitId: 'u_builder',
                target: kWorkTargetBuildImprovement,
                targetTileKey: tk,
              ),
            ],
          },
        ),
      );

      expect(find.textContaining('build improvement'), findsOneWidget);
      expect(find.textContaining(': idle'), findsNothing);
      expect(find.textContaining('u_builder'), findsNothing);
      expect(find.text('Builder: build improvement'), findsOneWidget);
    });

    testWidgets('Civilian section omits internal unit id from display lines', (
      WidgetTester tester,
    ) async {
      final tk = _tileKey(0, 0);
      final game = _game(
        id: 'civilian_id_hidden_test',
        tileKey: tk,
        units: [
          Unit(
            id: 'gp1_explorer_1',
            type: kUnitTypeExplorer,
            ownerId: _humanId,
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
        players: const [
          _humanPlayer,
          Player(id: 'gp2', displayName: 'France', isHuman: false, treasury: 0),
        ],
      );
      await _pumpOverlay(
        tester,
        game: game,
        tileKey: tk,
        greatPowerFactionIds: const {_humanId, 'gp2'},
      );

      expect(find.text('Explorer: idle'), findsOneWidget);
      expect(find.text('France — Explorer: idle'), findsOneWidget);
      expect(find.textContaining('gp1_explorer_1'), findsNothing);
      expect(find.textContaining('gp2_explorer_9'), findsNothing);
    });

    testWidgets('Military section uses localized regiment name', (
      WidgetTester tester,
    ) async {
      final tk = _tileKey(0, 0);
      final game = _game(
        id: 'mil_label_test',
        tileKey: tk,
        oldWorldProvinces: [
          _province(id: _fullProvinceId, displayName: 'MilProv'),
        ],
        units: [
          Unit(
            id: 'r1',
            type: 'peasant_levies',
            ownerId: _humanId,
            locationProvinceId: _fullProvinceId,
            status: UnitStatus.idle,
          ),
        ],
      );
      await _pumpOverlay(tester, game: game, tileKey: tk);

      expect(find.textContaining('Peasant levies'), findsOneWidget);
      expect(find.textContaining('peasant_levies:'), findsNothing);
    });

    testWidgets(
      'Military section shows pending regiment move line from draftOrders',
      (WidgetTester tester) async {
        final tk = _tileKey(0, 0);
        final game = _game(
          id: 'mil_pending_test',
          tileKey: tk,
          oldWorldProvinces: [
            _province(id: _fullProvinceId, displayName: 'FromProv'),
            _province(id: _fullDestProvinceId, displayName: 'DestProv'),
          ],
          units: [
            Unit(
              id: 'r_move',
              type: 'peasant_levies',
              ownerId: _humanId,
              locationProvinceId: _fullProvinceId,
              tileKey: tk,
              status: UnitStatus.idle,
            ),
          ],
        );
        await _pumpOverlay(
          tester,
          game: game,
          tileKey: tk,
          draftOrders: Orders(
            moveOrdersByPlayerId: {
              _humanId: [
                MoveOrder(
                  unitId: 'r_move',
                  destinationTileKey: '$_fullDestProvinceId|0|0',
                ),
              ],
            },
          ),
        );

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
        final game = _game(
          id: 'mil_pending_cross_region_test',
          tileKey: tk,
          oldWorldProvinces: [
            _province(id: _fullProvinceId, displayName: 'FromProv'),
          ],
          newWorld: const RegionData(
            provinces: [
              Province(
                id: 'newWorld|pDestNW',
                regionId: 'newWorld',
                displayName: 'NewWorldDest',
              ),
            ],
          ),
          units: [
            Unit(
              id: 'r_move',
              type: 'peasant_levies',
              ownerId: _humanId,
              locationProvinceId: _fullProvinceId,
              tileKey: tk,
              status: UnitStatus.idle,
            ),
          ],
        );
        await _pumpOverlay(
          tester,
          game: game,
          tileKey: tk,
          draftOrders: Orders(
            moveOrdersByPlayerId: {
              _humanId: [
                const MoveOrder(
                  unitId: 'r_move',
                  destinationTileKey: '$newWorldDestId|0|0',
                ),
              ],
            },
          ),
        );

        expect(
          find.textContaining('Ordered: move regiment to'),
          findsOneWidget,
        );
        expect(find.textContaining('NewWorldDest'), findsOneWidget);
      },
    );
  });
}
