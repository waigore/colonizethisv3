// Pin the 320 dp minimum-viewport contract for the two in-game move
// dialogs that share the [CtDialogShell] chrome but live outside the
// existing `dialogs_320dp_min_viewport_test.dart` family because they
// require a non-trivial `Game` + `MapTopology` fixture for the
// destination probe:
//
//  * [MoveArmyDialog]  — opened from the non-Home army row Move action
//    in `MilitaryUnitsPanel` (SPEC/ui/move-army-dialog.md). The shell
//    hosts up to two `CtSectionLabel`-headed destination groups (YOUR
//    PROVINCES, INVASION TARGETS) plus a trailing Cancel + Confirm
//    `CtNinePatchButton` action row.
//  * [MoveFleetDialog] — opened from the non-Home fleet row Move action
//    in `NavalUnitsPanel` (SPEC/ui/move-fleet-dialog.md). The shell
//    hosts up to two `CtSectionLabel`-headed destination groups (SEA
//    ZONES, PORTS) plus the same Cancel + Confirm action row.
//
// Both dialogs render their chrome via [CtDialogShell] (`maxWidth: 480`
// default; `Dialog.insetPadding: 16`). At [kMinViewportWidth] (320 dp)
// the inset padding dominates so the content column collapses to
// ~288 dp — the same narrow budget the `dialogs_320dp_min_viewport`
// pins already exercise for [GameParametersDialog], [TurnNewsDialog],
// etc. The pins assert:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception escapes the framework — the contract the other
//    `*_320dp_min_viewport_test.dart` files rely on.
//  * The localized title, both Cancel and Confirm action labels, and
//    at least one destination row label render end-to-end so the
//    layout actually exercises the dialog body at 320 dp rather than
//    no-op'ing.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixture so a regression in the host overflow
//    contract upstream of the dialog itself would be caught.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/move-army-dialog.md` § Layout / wireframe.
// SPEC: `SPEC/ui/move-fleet-dialog.md` § Layout / wireframe.
// Refs #2870 S8 (dialogs scale at narrow widths) + S10 (no horizontal
// overflow at 320 dp on every covered surface).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/move_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/move_fleet_dialog.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimum supported viewport dimensions for `SPEC/ui/mobile-adaptation.md`
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing dialog-level pin file `dialogs_320dp_min_viewport_test.dart`.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same dialog renders its default layout. Mirrors
/// the contract used by `dialogs_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

const String _humanPlayerId = 'gp_move_320_human';
const String _rivalPlayerId = 'gp_move_320_rival';

const String _ownedFrom = 'oldWorld|p_320_from';
const String _ownedDest = 'oldWorld|p_320_owned_dest';
const String _invasionDest = 'oldWorld|p_320_invasion_dest';

const String _originSea = 'sea_320_origin';
const String _adjacentSea = 'sea_320_adjacent';
const String _capitalProvince = 'oldWorld|p_320_capital';

/// Pumps [dialog] at [size] under the running editorial-monocle theme.
///
/// Sets the surface size (so the binding's render-flex math sees the
/// minimum viewport) and overrides MediaQuery so dialog code that reads
/// `MediaQuery.sizeOf(context).width` resolves to the same value — the
/// pattern already used by `dialogs_320dp_min_viewport_test.dart`.
///
/// Embeds [dialog] directly in the Scaffold body rather than driving
/// the real `showDialog` flow because the contract under test is the
/// dialog's own [CtDialogShell] layout at the narrow viewport, not the
/// barrier / overlay route plumbing (which is already covered by
/// `move_dialogs_specs_test.dart`).
Future<void> _pumpDialogAtSize(
  WidgetTester tester,
  Widget dialog, {
  required Size size,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: Center(child: dialog)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MapTopology _buildArmyTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(
        id: _ownedFrom,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: _ownedDest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: _invasionDest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [
      TopologyEdge(id1: _ownedFrom, id2: _ownedDest),
      TopologyEdge(id1: _ownedFrom, id2: _invasionDest),
    ],
  );
}

Game _buildArmyGame() {
  return Game(
    id: 'g_move_army_320',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: _ownedFrom,
            regionId: 'oldWorld',
            ownerId: _humanPlayerId,
            displayName: 'Origin',
          ),
          Province(
            id: _ownedDest,
            regionId: 'oldWorld',
            ownerId: _humanPlayerId,
            displayName: 'Owned Dest',
          ),
          Province(
            id: _invasionDest,
            regionId: 'oldWorld',
            ownerId: _rivalPlayerId,
            displayName: 'Invade Dest',
          ),
        ],
        units: [
          Unit(
            id: 'u_move_320',
            type: 'musketeers',
            ownerId: _humanPlayerId,
            locationProvinceId: _ownedFrom,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: const [
        Army(
          id: 'a_move_320',
          ownerId: _humanPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: _ownedFrom,
          regimentUnitIds: ['u_move_320'],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          _ownedFrom: ['oldWorld|p_320_from|0|0'],
          _ownedDest: ['oldWorld|p_320_owned_dest|0|0'],
          _invasionDest: ['oldWorld|p_320_invasion_dest|0|0'],
        },
      },
      playerVisibilityByTile: const {
        _humanPlayerId: {
          'oldWorld|p_320_from|0|0': 'fullyVisible',
          'oldWorld|p_320_owned_dest|0|0': 'fullyVisible',
          'oldWorld|p_320_invasion_dest|0|0': 'fullyVisible',
        },
      },
    ),
    players: const [
      Player(
        id: _humanPlayerId,
        displayName: 'Mobile Player',
        isHuman: true,
        capitalProvinceId: _ownedFrom,
      ),
      Player(
        id: _rivalPlayerId,
        displayName: 'Mobile Rival',
        isHuman: false,
        capitalProvinceId: _invasionDest,
      ),
    ],
  );
}

MapTopology _buildFleetTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(
        id: _originSea,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: _adjacentSea,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: _originSea, id2: _adjacentSea)],
  );
}

Game _buildFleetGame() {
  return Game(
    id: 'g_move_fleet_320',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: _capitalProvince,
            regionId: 'oldWorld',
            ownerId: _humanPlayerId,
            displayName: 'Capital Port',
          ),
        ],
      ),
      newWorld: const RegionData(),
      portsByProvinceSeaboard: const {
        'oldWorld|p_320_capital|sea_320_origin': 'oldWorld|p_320_capital|0|0',
        'oldWorld|p_320_capital|sea_320_adjacent': 'oldWorld|p_320_capital|0|0',
      },
      seaZoneDisplayNameById: const {
        'oldWorld|sea_320_origin': 'Origin Sea',
        'oldWorld|sea_320_adjacent': 'Adjacent Sea',
      },
    ),
    players: const [
      Player(
        id: _humanPlayerId,
        displayName: 'Mobile Admiral',
        isHuman: true,
        capitalProvinceId: _capitalProvince,
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: _capitalProvince,
          x: 0,
          y: 0,
        ),
      ),
    ],
  );
}

Fleet _buildFleet() {
  return Fleet(
    id: 'f_move_320',
    ownerId: _humanPlayerId,
    regionId: 'oldWorld',
    seaZoneId: _originSea,
    ships: const [ShipInstance(id: 'ship_move_320', typeId: 'carrack')],
  );
}

MoveArmyDialog _buildMoveArmyDialog() {
  final game = _buildArmyGame();
  final topology = _buildArmyTopology();
  final army = game.worldState.armies.first;
  return MoveArmyDialog(
    army: army,
    game: game,
    humanPlayerId: _humanPlayerId,
    bus: AppEventBus.create(),
    topology: topology,
    draftOrders: const Orders(),
  );
}

MoveFleetDialog _buildMoveFleetDialog() {
  final game = _buildFleetGame();
  final topology = _buildFleetTopology();
  final fleet = _buildFleet();
  return MoveFleetDialog(
    game: game,
    topology: topology,
    humanPlayerId: _humanPlayerId,
    fleet: fleet,
    bus: AppEventBus.create(),
  );
}

void main() {
  suppressLogsForTests();

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — MoveArmyDialog @ 320 dp '
    '(Refs #2870 S8/S10)',
    () {
      testWidgets(
        'AC (positive) MoveArmyDialog @ 320×640: no RenderFlex overflow '
        'exception, title + YOUR PROVINCES + Cancel + Confirm all render',
        (WidgetTester tester) async {
          await _pumpDialogAtSize(
            tester,
            _buildMoveArmyDialog(),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: MoveArmyDialog must not '
                'emit a RenderFlex overflow exception at kMinViewportWidth '
                '(320 dp). CtDialogShell at 320 dp collapses to ~288 dp '
                'content width — the title row, both CtSectionLabel '
                'headers, the destination radio rows, and the trailing '
                'Cancel + Confirm action row must all wrap within that.',
          );
          expect(find.byType(MoveArmyDialog), findsOneWidget);
          expect(find.textContaining('Move army'), findsOneWidget);
          // CtSectionLabel renders text upper-cased.
          expect(find.text('YOUR PROVINCES'), findsOneWidget);
          expect(find.text('INVASION TARGETS'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);
          expect(find.text('Confirm'), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: MoveArmyDialog @ 1024×768 also pumps without '
        'exception (regression sentinel for the overflow contract — '
        'keeps the 320 dp positive pin meaningful)',
        (WidgetTester tester) async {
          await _pumpDialogAtSize(
            tester,
            _buildMoveArmyDialog(),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(MoveArmyDialog), findsOneWidget);
          expect(find.textContaining('Move army'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);
          expect(find.text('Confirm'), findsOneWidget);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — MoveFleetDialog @ 320 dp '
    '(Refs #2870 S8/S10)',
    () {
      testWidgets(
        'AC (positive) MoveFleetDialog @ 320×640: no RenderFlex overflow '
        'exception, title + SEA ZONES + Cancel + Confirm all render',
        (WidgetTester tester) async {
          await _pumpDialogAtSize(
            tester,
            _buildMoveFleetDialog(),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: MoveFleetDialog must not '
                'emit a RenderFlex overflow exception at kMinViewportWidth '
                '(320 dp). CtDialogShell at 320 dp collapses to ~288 dp '
                'content width — the title row, the SEA ZONES '
                'CtSectionLabel, the sea-zone radio rows, and the trailing '
                'Cancel + Confirm action row must all wrap within that.',
          );
          expect(find.byType(MoveFleetDialog), findsOneWidget);
          expect(find.textContaining('Move fleet'), findsOneWidget);
          // CtSectionLabel renders text upper-cased; SEA ZONES is the
          // guaranteed section for the single-sea-zone destination
          // fixture.
          expect(find.text('SEA ZONES'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);
          expect(find.text('Confirm'), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: MoveFleetDialog @ 1024×768 also pumps without '
        'exception (regression sentinel for the overflow contract — '
        'keeps the 320 dp positive pin meaningful)',
        (WidgetTester tester) async {
          await _pumpDialogAtSize(
            tester,
            _buildMoveFleetDialog(),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(MoveFleetDialog), findsOneWidget);
          expect(find.textContaining('Move fleet'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);
          expect(find.text('Confirm'), findsOneWidget);
        },
      );
    },
  );
}
