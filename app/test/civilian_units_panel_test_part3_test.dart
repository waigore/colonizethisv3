// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        kWorkTargetBuildFort,
        kWorkTargetBuildImprovement,
        kWorkTargetBuildPort,
        kWorkTargetBuildRail,
        kWorkTargetBuildRoad,
        kWorkTargetCounterSpy,
        kWorkTargetExplore,
        kWorkTargetProspect,
        kWorkTargetPurchaseLand,
        kWorkTargetStealTech,
        kWorkTargetUpgradeTown;

class _EventHandlingWrapper extends StatefulWidget {
  const _EventHandlingWrapper({
    required this.bus,
    required this.child,
    required this.navigatorKey,
  });

  final AppEventBus bus;
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<_EventHandlingWrapper> createState() => _EventHandlingWrapperState();
}

class _EventHandlingWrapperState extends State<_EventHandlingWrapper> {
  StreamSubscription? _confirmSub;
  StreamSubscription? _closeSub;

  @override
  void initState() {
    super.initState();
    _closeSub = widget.bus.on<ClosePanelEvent>().listen((_) {
      widget.navigatorKey.currentState?.maybePop();
    });
    _confirmSub = widget.bus.on<ConfirmDialogEvent>().listen((event) async {
      final nav = widget.navigatorKey.currentState;
      if (nav == null) return;
      final result = await showDialog<bool>(
        context: nav.context,
        builder: (ctx) => AlertDialog(
          title: Text(event.title),
          content: Text(event.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(event.cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(event.confirmLabel),
            ),
          ],
        ),
      );
      event.result(result ?? false);
    });
  }

  @override
  void dispose() {
    _confirmSub?.cancel();
    _closeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;
  const String humanPlayerIdWithNoUnits = 'no-such-player';

  setUpAll(() {
    game = getDebugInitGameResult().game;
    humanPlayerIdWithUnits = game.players.isNotEmpty
        ? game.players.first.id
        : 'gp1';
  });

  Widget buildPanel({
    required Game game,
    required String humanPlayerId,
    Orders currentOrders = const Orders(),
    Map<String, List<String>> availableWorkTargets = const {},
    AppEventBus? bus,
    bool explorerOnly = false,
    bool builderOnly = false,
    String? prospectShortcutTargetTileKey,
    String? exploreShortcutTargetTileKey,
    String? buildImprovementShortcutTargetTileKey,
  }) {
    final resolvedBus = bus ?? AppEventBus.create();
    final navigatorKey = GlobalKey<NavigatorState>();
    return ProviderScope(
      overrides: [
        availableWorkTargetIdsForUnitProvider.overrideWith(
          (ref, unitId) => availableWorkTargets[unitId] ?? const [],
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: _EventHandlingWrapper(
            bus: resolvedBus,
            navigatorKey: navigatorKey,
            child: CivilianUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              currentOrders: currentOrders,
              bus: resolvedBus,
              explorerOnly: explorerOnly,
              builderOnly: builderOnly,
              prospectShortcutTargetTileKey: prospectShortcutTargetTileKey,
              exploreShortcutTargetTileKey: exploreShortcutTargetTileKey,
              buildImprovementShortcutTargetTileKey:
                  buildImprovementShortcutTargetTileKey,
            ),
          ),
        ),
      ),
    );
  }

  group('CivilianUnitsPanel', () {
    testWidgets(
      'AC: pending build_improvement shows ResourceIcons and omits (pending)',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = Game(
          id: 'g_civ_pending_build',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'Alpha',
                ),
              ],
              units: [
                Unit(
                  id: 'b1',
                  type: kUnitTypeBuilder,
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: human, displayName: 'Human', isHuman: true),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            human: [
              WorkOrder(
                unitId: 'b1',
                target: kWorkTargetBuildImprovement,
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        await tester.pumpWidget(
          buildPanel(
            game: miniGame,
            humanPlayerId: human,
            currentOrders: orders,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Assigned to:'), findsOneWidget);
        expect(find.textContaining('(pending)'), findsNothing);
        expect(
          find.byWidgetPredicate(
            (w) => w is ResourceIcon && w.commodityId == 'lumber',
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is ResourceIcon && w.commodityId == 'castIron',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC: pending explore shows inline turns and no ResourceIcon strip',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = Game(
          id: 'g_civ_pending_explore',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'Alpha',
                ),
              ],
              units: [
                Unit(
                  id: 'e1',
                  type: kUnitTypeExplorer,
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: human, displayName: 'Human', isHuman: true),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            human: [
              WorkOrder(
                unitId: 'e1',
                target: kWorkTargetExplore,
                targetTileKey: 'oldWorld|p1|0|0',
              ),
            ],
          },
        );
        await tester.pumpWidget(
          buildPanel(
            game: miniGame,
            humanPlayerId: human,
            currentOrders: orders,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('(pending)'), findsNothing);
        expect(find.textContaining('Assigned to: Explore'), findsOneWidget);
        expect(find.textContaining('turn'), findsAtLeastNWidgets(1));
        expect(find.byType(ResourceIcon), findsNothing);
      },
    );

    testWidgets(
      'AC: pending purchase_land shows treasury chip not ResourceIcon',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = Game(
          id: 'g_civ_pending_land',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'Alpha',
                ),
              ],
              units: [
                Unit(
                  id: 'm1',
                  type: kUnitTypeMerchant,
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: {tileKey: 'grain'},
          ),
          players: const [
            Player(id: human, displayName: 'Human', isHuman: true),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            human: [
              WorkOrder(
                unitId: 'm1',
                target: kWorkTargetPurchaseLand,
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        await tester.pumpWidget(
          buildPanel(
            game: miniGame,
            humanPlayerId: human,
            currentOrders: orders,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Treasury:'), findsOneWidget);
        expect(find.textContaining('(pending)'), findsNothing);
        expect(find.byType(ResourceIcon), findsNothing);
      },
    );

    testWidgets(
      'AC: pending purchase_land without tile resource still shows inline turns',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = Game(
          id: 'g_civ_pending_land_nores',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'Alpha',
                ),
              ],
              units: [
                Unit(
                  id: 'm1',
                  type: kUnitTypeMerchant,
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: human, displayName: 'Human', isHuman: true),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            human: [
              WorkOrder(
                unitId: 'm1',
                target: kWorkTargetPurchaseLand,
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        await tester.pumpWidget(
          buildPanel(
            game: miniGame,
            humanPlayerId: human,
            currentOrders: orders,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('(pending)'), findsNothing);
        expect(
          find.textContaining('Assigned to: Purchase land'),
          findsOneWidget,
        );
        expect(find.textContaining('turn'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Treasury:'), findsNothing);
      },
    );

    testWidgets(
      'AC: pending rows show faithful remaining-turn number for each work target',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        const targetTileKey = 'oldWorld|p1|1|0';
        final cases = <({String unitType, String target, int turns})>[
          (unitType: kUnitTypeExplorer, target: kWorkTargetExplore, turns: 3),
          (unitType: kUnitTypeExplorer, target: kWorkTargetProspect, turns: 1),
          (
            unitType: kUnitTypeBuilder,
            target: kWorkTargetBuildImprovement,
            turns: 1,
          ),
          (
            unitType: kUnitTypeBuilder,
            target: kWorkTargetUpgradeTown,
            turns: 1,
          ),
          (unitType: kUnitTypeEngineer, target: kWorkTargetBuildRoad, turns: 1),
          (unitType: kUnitTypeEngineer, target: kWorkTargetBuildPort, turns: 1),
          (unitType: kUnitTypeEngineer, target: kWorkTargetBuildFort, turns: 3),
          (
            unitType: kUnitTypeRailBuilder,
            target: kWorkTargetBuildRail,
            turns: 1,
          ),
          (unitType: kUnitTypeSpy, target: kWorkTargetStealTech, turns: 5),
          (unitType: kUnitTypeSpy, target: kWorkTargetCounterSpy, turns: 1),
          (
            unitType: kUnitTypeMerchant,
            target: kWorkTargetPurchaseLand,
            turns: 1,
          ),
        ];

        for (var i = 0; i < cases.length; i++) {
          final c = cases[i];
          final unitId = 'u_$i';
          final miniGame = Game(
            id: 'g_civ_pending_turns_${c.target}_$i',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: RegionData(
                provinces: const [
                  Province(
                    id: 'oldWorld|p1',
                    regionId: 'oldWorld',
                    displayName: 'Alpha',
                    fortLevel: 2,
                  ),
                ],
                units: [
                  Unit(
                    id: unitId,
                    type: c.unitType,
                    ownerId: human,
                    locationProvinceId: 'oldWorld|p1',
                    tileKey: tileKey,
                  ),
                ],
              ),
              newWorld: const RegionData(),
              resourceByTileKey: const {targetTileKey: 'grain'},
              tileKeysByRegionAndProvince: const {
                'oldWorld': {
                  'oldWorld|p1': [tileKey, targetTileKey],
                },
              },
            ),
            players: const [
              Player(id: human, displayName: 'Human', isHuman: true),
            ],
          );
          final orders = Orders(
            workOrdersByPlayerId: {
              human: [
                WorkOrder(
                  unitId: unitId,
                  target: c.target,
                  targetTileKey: targetTileKey,
                ),
              ],
            },
          );
          await tester.pumpWidget(
            buildPanel(
              game: miniGame,
              humanPlayerId: human,
              currentOrders: orders,
            ),
          );
          await tester.pumpAndSettle();

          final lineFinder = find.textContaining('Assigned to:');
          expect(
            lineFinder,
            findsOneWidget,
            reason: 'Expected one Assigned to line for target ${c.target}',
          );
          final line = tester.widget<Text>(lineFinder).data ?? '';
          final singular = '${c.turns} turn';
          final plural = '${c.turns} turns';
          expect(
            line.contains(singular) || line.contains(plural),
            isTrue,
            reason:
                'Expected target ${c.target} to show $singular/$plural, got: $line',
          );
          expect(
            line.contains('# turn'),
            isFalse,
            reason: 'Target ${c.target} should not render placeholder text',
          );
        }
      },
    );

    testWidgets('AC: pending build_rail shows steel and lumber icons', (
      WidgetTester tester,
    ) async {
      const human = 'h1';
      const tileKey = 'oldWorld|p1|0|0';
      final miniGame = Game(
        id: 'g_civ_pending_rail',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                displayName: 'Alpha',
              ),
            ],
            units: [
              Unit(
                id: 'r1',
                type: kUnitTypeRailBuilder,
                ownerId: human,
                locationProvinceId: 'oldWorld|p1',
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: human, displayName: 'Human', isHuman: true)],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          human: [
            WorkOrder(
              unitId: 'r1',
              target: kWorkTargetBuildRail,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      await tester.pumpWidget(
        buildPanel(game: miniGame, humanPlayerId: human, currentOrders: orders),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('(pending)'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is ResourceIcon && w.commodityId == 'lumber',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is ResourceIcon && w.commodityId == 'steel',
        ),
        findsOneWidget,
      );
    });

    testWidgets('AC: in-progress work row has no pending cost ResourceIcons', (
      WidgetTester tester,
    ) async {
      const human = 'h1';
      const tileKey = 'oldWorld|p1|0|0';
      final miniGame = Game(
        id: 'g_civ_working',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                displayName: 'Alpha',
              ),
            ],
            units: [
              Unit(
                id: 'b1',
                type: kUnitTypeBuilder,
                ownerId: human,
                locationProvinceId: 'oldWorld|p1',
                tileKey: tileKey,
                status: UnitStatus.working,
                currentWork: const CurrentWork(
                  workTarget: kWorkTargetBuildImprovement,
                  tileKey: tileKey,
                  totalTurns: 5,
                  remainingTurns: 2,
                ),
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: human, displayName: 'Human', isHuman: true)],
      );
      await tester.pumpWidget(buildPanel(game: miniGame, humanPlayerId: human));
      await tester.pumpAndSettle();

      expect(find.textContaining('2/5'), findsOneWidget);
      expect(find.byType(ResourceIcon), findsNothing);
    });

    testWidgets(
      'tile-scoped mode: Tile then Train in header; no Tile on unit rows',
      (WidgetTester tester) async {
        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final civilianWithTile = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u),
        );
        if (civilianWithTile.isEmpty) return;
        final scopedTileKey = civilianWithTile.first.tileKey!;
        final scopedUnitId = civilianWithTile.first.id;
        final bus = AppEventBus.create();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              availableWorkTargetIdsForUnitProvider.overrideWith(
                (ref, _) => const <String>[],
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: CivilianUnitsPanel(
                  game: game,
                  humanPlayerId: humanPlayerIdWithUnits,
                  currentOrders: const Orders(),
                  bus: bus,
                  tileScopeTileKey: scopedTileKey,
                  initialSelectedUnitId: scopedUnitId,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Civilian Units (Tile)'), findsOneWidget);
        expect(find.text('Tile'), findsOneWidget);

        // Header actions are compact primary pills (CtActionTextButton,
        // not CtNinePatchButton) per #3514 owner decision #5.
        final shellButtons = find.descendant(
          of: find.byType(UnitsPanelShell),
          matching: find.byType(CtActionTextButton),
        );
        expect(
          find.descendant(of: shellButtons.at(0), matching: find.text('Tile')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: shellButtons.at(1), matching: find.text('Train')),
          findsOneWidget,
        );

        expect(
          find.descendant(
            of: find.byType(CivilianUnitRowCard),
            matching: find.text('Tile'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('tile-scoped empty list: header Tile is disabled', (
      WidgetTester tester,
    ) async {
      final bus = AppEventBus.create();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availableWorkTargetIdsForUnitProvider.overrideWith(
              (ref, _) => const <String>[],
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CivilianUnitsPanel(
                game: game,
                humanPlayerId: humanPlayerIdWithUnits,
                bus: bus,
                tileScopeTileKey:
                    'oldWorld|no_civilian_units_on_this_province|0|0',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Civilian Units (Tile)'), findsOneWidget);
      expect(find.text('No civilian units'), findsOneWidget);
      final tileButton = find.ancestor(
        of: find.text('Tile'),
        matching: find.byType(CtActionTextButton),
      );
      expect(tester.widget<CtActionTextButton>(tileButton).enabled, isFalse);
    });

    testWidgets(
      'full-list header Train renders as a primary CtActionTextButton pill '
      '(no CtNinePatchButton header chrome) — #3514 owner decision #5',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              availableWorkTargetIdsForUnitProvider.overrideWith(
                (ref, _) => const <String>[],
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: CivilianUnitsPanel(
                  game: game,
                  humanPlayerId: humanPlayerIdWithUnits,
                  bus: bus,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Scope to the header Train pill by label: row-action Assign pills are
        // now also CtActionTextButton (#3514 row-action migration), so the
        // header control is resolved via its 'Train' label rather than the
        // first CtActionTextButton in the shell.
        final trainLabel = find.descendant(
          of: find.byType(UnitsPanelShell),
          matching: find.text('Train'),
        );
        expect(trainLabel, findsOneWidget);
        final trainButtonFinder = find.ancestor(
          of: trainLabel,
          matching: find.byType(CtActionTextButton),
        );
        expect(trainButtonFinder, findsOneWidget);
        final trainButton = tester.widget<CtActionTextButton>(
          trainButtonFinder,
        );
        expect(trainButton.primary, isTrue);
        expect(trainButton.label, 'Train');
      },
    );

    testWidgets(
      'tile-scoped header Tile emits OpenMapTileDetailEvent for rendered tile',
      (WidgetTester tester) async {
        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final civilian = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u),
        );
        if (civilian.isEmpty) return;
        final u = civilian.first;
        final rendered = u.assignedTileKey?.isNotEmpty == true
            ? u.assignedTileKey!
            : u.tileKey!;

        final bus = AppEventBus.create();
        OpenMapTileDetailEvent? captured;
        final sub = bus.on<OpenMapTileDetailEvent>().listen((e) {
          captured = e;
        });
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              availableWorkTargetIdsForUnitProvider.overrideWith(
                (ref, _) => const <String>[],
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: CivilianUnitsPanel(
                  game: game,
                  humanPlayerId: humanPlayerIdWithUnits,
                  bus: bus,
                  tileScopeTileKey: rendered,
                  initialSelectedUnitId: u.id,
                ),
              ),
            ),
          ),
        );
        // Avoid pumpAndSettle: nine-patch buttons may not settle in widget tests.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        captured = null;
        await tester.tap(find.text('Tile'));
        await tester.pump();
        await tester.pump();
        expect(captured, isNotNull);
        expect(captured?.tileKey, rendered);
      },
    );
  });
}

bool _isCivilian(Unit unit) {
  final role = unitRoleForType(unit.type);
  if (role == null) return false;
  return role != UnitRole.military && role != UnitRole.naval;
}
