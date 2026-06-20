// Tests for MilitaryUnitsPanel. SPEC/ui/military-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

/// Applies [ArmySplitRequestedEvent] like [AppEventHandlerScope] and rebuilds
/// the panel with updated [Game] (widget tests do not mount full shell).
class _ArmySplitTestHarness extends StatefulWidget {
  const _ArmySplitTestHarness({
    required this.initialGame,
    required this.humanPlayerId,
    required this.bus,
  });

  final Game initialGame;
  final String humanPlayerId;
  final AppEventBus bus;

  @override
  State<_ArmySplitTestHarness> createState() => _ArmySplitTestHarnessState();
}

class _ArmySplitTestHarnessState extends State<_ArmySplitTestHarness> {
  late Game _game;
  StreamSubscription<ArmySplitRequestedEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _game = widget.initialGame;
    _sub = widget.bus.on<ArmySplitRequestedEvent>().listen((e) {
      final next = applyArmySplit(
        game: _game,
        playerId: e.humanPlayerId,
        sourceArmyId: e.sourceArmyId,
        unitIdsToMove: e.unitIdsToMove,
      );
      setState(() => _game = next);
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MilitaryUnitsPanel(
      game: _game,
      humanPlayerId: widget.humanPlayerId,
      bus: widget.bus,
      topology: const MapTopology(),
      draftOrders: const Orders(),
    );
  }
}

void main() {
  suppressLogsForTests();

  group('Army management (bus events) — split UI', () {
    testWidgets(
      'split home army (all regiments): panel shows new army with regiment rows',
      (WidgetTester tester) async {
        const playerId = 'gp_split_ui_full';
        const cap = 'oldWorld|cap';
        final initial = Game(
          id: 'g_split_full',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: cap,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  displayName: 'Capital',
                  townTileKey: 'tk_cap',
                ),
              ],
              units: [
                Unit(
                  id: 'r1',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: cap,
                ),
                Unit(
                  id: 'r2',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: cap,
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: [
              Army(
                id: 'home_army',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: cap,
                regimentUnitIds: const ['r1', 'r2'],
                isHomeArmy: true,
              ),
            ],
            nextArmySeq: 1,
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                cap: ['tk_cap'],
              },
            },
          ),
          players: [
            Player(
              id: playerId,
              displayName: 'Splitter',
              isHuman: true,
              capitalProvinceId: cap,
            ),
          ],
        );

        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 900,
                width: 480,
                child: _ArmySplitTestHarness(
                  initialGame: initial,
                  humanPlayerId: playerId,
                  bus: bus,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Army').first;
        await tester.tap(homeTile);
        await tester.pumpAndSettle();

        final splitBtn = find.descendant(
          of: homeTile,
          matching: find.widgetWithText(CtActionTextButton, 'Split'),
        ).first;
        await tester.ensureVisible(splitBtn);
        await tester.tap(splitBtn);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(CtTransferListKeys.leftMoveAll('musketeers')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm Split'));
        // Broadcast bus delivers listeners asynchronously; flush like split_army_dialog_test.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('0 regiments · Capital'), findsOneWidget);
        expect(find.text('2 regiments · Capital'), findsOneWidget);

        await tester.tap(find.text('Army army_1'));
        await tester.pumpAndSettle();
        expect(find.text('Musketeers: 2'), findsOneWidget);
      },
    );

    testWidgets(
      'split home army (partial): panel shows correct counts on both armies',
      (WidgetTester tester) async {
        const playerId = 'gp_split_ui_partial';
        const cap = 'oldWorld|cap';
        final initial = Game(
          id: 'g_split_partial',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: cap,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  displayName: 'Capital',
                  townTileKey: 'tk_cap',
                ),
              ],
              units: [
                Unit(
                  id: 'r1',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: cap,
                ),
                Unit(
                  id: 'r2',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: cap,
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: [
              Army(
                id: 'home_army',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: cap,
                regimentUnitIds: const ['r1', 'r2'],
                isHomeArmy: true,
              ),
            ],
            nextArmySeq: 7,
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                cap: ['tk_cap'],
              },
            },
          ),
          players: [
            Player(
              id: playerId,
              displayName: 'Splitter',
              isHuman: true,
              capitalProvinceId: cap,
            ),
          ],
        );

        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 900,
                width: 480,
                child: _ArmySplitTestHarness(
                  initialGame: initial,
                  humanPlayerId: playerId,
                  bus: bus,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Army').first;
        await tester.tap(homeTile);
        await tester.pumpAndSettle();

        final splitBtn = find.descendant(
          of: homeTile,
          matching: find.widgetWithText(CtActionTextButton, 'Split'),
        ).first;
        await tester.ensureVisible(splitBtn);
        await tester.tap(splitBtn);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(CtTransferListKeys.leftMoveOne('musketeers')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm Split'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('1 regiments · Capital'), findsNWidgets(2));

        // After the in-place split rebuild the Home Army row stays expanded
        // (tapping the Split row-action pill no longer toggles the
        // ExpansionTile, since the CtActionTextButton InkWell absorbs the tap),
        // so its single musketeer is already visible.
        expect(find.text('Musketeers: 1'), findsOneWidget);

        await tester.tap(find.text('Army army_7'));
        await tester.pumpAndSettle();
        expect(find.text('Musketeers: 1'), findsNWidgets(2));
      },
    );
  });
}
