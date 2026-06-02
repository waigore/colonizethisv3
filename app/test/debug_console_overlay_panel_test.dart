import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/debug_console_overlay_panel.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('DebugConsoleOverlayPanel', () {
    testWidgets('submitting valid command emits spawn event', (tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <SpawnDebugCivilianAtCapitalEvent>[];
      final sub = bus.on<SpawnDebugCivilianAtCapitalEvent>().listen(events.add);
      addTearDown(sub.cancel);
      final snackbars = <ShowSnackBarEvent>[];
      final snackbarSub = bus.on<ShowSnackBarEvent>().listen(snackbars.add);
      addTearDown(snackbarSub.cancel);
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleOverlayPanel(
              bus: bus,
              humanPlayerId: 'human_1',
              readOnlyContextProvider: () =>
                  const DebugConsoleReadOnlyContext(),
              onClose: () => closed = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey<String>('debug-console-input')),
        '/spawn_civilian explorer 2',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(events, hasLength(1));
      expect(events.single.humanPlayerId, 'human_1');
      expect(events.single.unitType, kUnitTypeExplorer);
      expect(events.single.count, 2);
      expect(snackbars, isNotEmpty);
      expect(
        snackbars.last.message,
        'Queued debug spawn: 2x Explorer at capital.',
      );
      expect(closed, isFalse);
    });

    testWidgets('submitting valid add_money emits treasury credit event', (
      tester,
    ) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <CreditDebugTreasuryEvent>[];
      final sub = bus.on<CreditDebugTreasuryEvent>().listen(events.add);
      addTearDown(sub.cancel);
      final snackbars = <ShowSnackBarEvent>[];
      final snackbarSub = bus.on<ShowSnackBarEvent>().listen(snackbars.add);
      addTearDown(snackbarSub.cancel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleOverlayPanel(
              bus: bus,
              humanPlayerId: 'human_1',
              readOnlyContextProvider: () =>
                  const DebugConsoleReadOnlyContext(),
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey<String>('debug-console-input')),
        '/add_money 42',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(events, hasLength(1));
      expect(events.single.humanPlayerId, 'human_1');
      expect(events.single.requestedAmount, 42);
      expect(events.single.creditedAmount, 42);
      expect(snackbars.last.message, contains('42'));
    });

    testWidgets('submitting valid spawn_regiment emits regiment event', (
      tester,
    ) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <SpawnDebugRegimentAtCapitalEvent>[];
      final sub = bus.on<SpawnDebugRegimentAtCapitalEvent>().listen(events.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleOverlayPanel(
              bus: bus,
              humanPlayerId: 'human_1',
              readOnlyContextProvider: () =>
                  const DebugConsoleReadOnlyContext(),
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey<String>('debug-console-input')),
        '/spawn_regiment peasant_levies 2',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(events, hasLength(1));
      expect(events.single.humanPlayerId, 'human_1');
      expect(events.single.regimentTypeId, 'peasant_levies');
      expect(events.single.count, 2);
    });

    testWidgets('submitting valid spawn_ship emits ship spawn event', (
      tester,
    ) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <SpawnDebugShipAtCapitalHomeFleetEvent>[];
      final sub = bus.on<SpawnDebugShipAtCapitalHomeFleetEvent>().listen(
        events.add,
      );
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleOverlayPanel(
              bus: bus,
              humanPlayerId: 'human_1',
              readOnlyContextProvider: () =>
                  const DebugConsoleReadOnlyContext(),
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey<String>('debug-console-input')),
        '/spawn_ship carrack 2',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(events, hasLength(1));
      expect(events.single.humanPlayerId, 'human_1');
      expect(events.single.shipTypeId, 'carrack');
      expect(events.single.count, 2);
    });

    testWidgets('invalid command does not emit spawn event', (tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <SpawnDebugCivilianAtCapitalEvent>[];
      final sub = bus.on<SpawnDebugCivilianAtCapitalEvent>().listen(events.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleOverlayPanel(
              bus: bus,
              humanPlayerId: 'human_1',
              readOnlyContextProvider: () =>
                  const DebugConsoleReadOnlyContext(),
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey<String>('debug-console-input')),
        '/spawn_civilian unknown_type',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(events, isEmpty);
    });

    testWidgets('submitting flip_province emits ownership flip event', (
      tester,
    ) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <FlipDebugProvinceOwnershipEvent>[];
      final sub = bus.on<FlipDebugProvinceOwnershipEvent>().listen(events.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleOverlayPanel(
              bus: bus,
              humanPlayerId: 'human_1',
              readOnlyContextProvider: () =>
                  const DebugConsoleReadOnlyContext(),
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey<String>('debug-console-input')),
        '/flip_province oldWorld New Bordeaux',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(events, hasLength(1));
      expect(events.single.humanPlayerId, 'human_1');
      expect(events.single.regionId, 'oldWorld');
      expect(events.single.provinceDisplayName, 'New Bordeaux');
    });

    testWidgets(
      'submitting rail_builder command emits rail builder spawn event',
      (tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final events = <SpawnDebugCivilianAtCapitalEvent>[];
        final sub = bus.on<SpawnDebugCivilianAtCapitalEvent>().listen(
          events.add,
        );
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DebugConsoleOverlayPanel(
                bus: bus,
                humanPlayerId: 'human_1',
                readOnlyContextProvider: () =>
                    const DebugConsoleReadOnlyContext(),
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.enterText(
          find.byKey(const ValueKey<String>('debug-console-input')),
          '/spawn_civilian rail_builder 3',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(events, hasLength(1));
        expect(events.single.unitType, kUnitTypeRailBuilder);
        expect(events.single.count, 3);
      },
    );

    testWidgets('invalid command emits deterministic snackbar message', (
      tester,
    ) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final snackbars = <ShowSnackBarEvent>[];
      final sub = bus.on<ShowSnackBarEvent>().listen(snackbars.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleOverlayPanel(
              bus: bus,
              humanPlayerId: 'human_1',
              readOnlyContextProvider: () =>
                  const DebugConsoleReadOnlyContext(),
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey<String>('debug-console-input')),
        '/spawn_civilian unknown_type',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(snackbars, isNotEmpty);
      expect(
        snackbars.last.message,
        'Unknown civilian type. Use explorer, builder, engineer, spy, merchant, or rail_builder.',
      );
    });

    testWidgets('escape key triggers panel close callback', (tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      var closeCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleOverlayPanel(
              bus: bus,
              humanPlayerId: 'human_1',
              readOnlyContextProvider: () =>
                  const DebugConsoleReadOnlyContext(),
              onClose: () => closeCount += 1,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('debug-console-input')),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(closeCount, 1);
    });

    testWidgets('arrow up and down navigate submitted command history', (
      tester,
    ) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleOverlayPanel(
              bus: bus,
              humanPlayerId: 'human_1',
              readOnlyContextProvider: () =>
                  const DebugConsoleReadOnlyContext(),
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final inputFinder = find.byKey(
        const ValueKey<String>('debug-console-input'),
      );

      await tester.enterText(inputFinder, '/spawn_civilian explorer 1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      await tester.enterText(inputFinder, '/spawn_civilian builder 2');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      await tester.tap(inputFinder);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      EditableText editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(editableText.controller.text, '/spawn_civilian builder 2');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.controller.text, '/spawn_civilian explorer 1');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.controller.text, '/spawn_civilian builder 2');
    });

    testWidgets('/get_tile_basic_info reads selectedTileKey at submit-time', (
      tester,
    ) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <SessionCommandEvent>[];
      final eventSub = bus.on<SessionCommandEvent>().listen(events.add);
      addTearDown(eventSub.cancel);
      final snackbars = <ShowSnackBarEvent>[];
      final snackbarSub = bus.on<ShowSnackBarEvent>().listen(snackbars.add);
      addTearDown(snackbarSub.cancel);
      String? selectedTileKey = 'oldWorld|P12|34|21';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleOverlayPanel(
              bus: bus,
              humanPlayerId: 'human_1',
              readOnlyContextProvider: () =>
                  DebugConsoleReadOnlyContext(selectedTileKey: selectedTileKey),
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final inputFinder = find.byKey(
        const ValueKey<String>('debug-console-input'),
      );
      await tester.enterText(inputFinder, '/get_tile_basic_info');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(snackbars.last.message, contains('tile_id: oldWorld|P12|34|21'));
      expect(snackbars.last.message, contains('province_id: oldWorld|P12'));
      expect(events, isEmpty);

      selectedTileKey = 'oldWorld|P1|2|3';
      await tester.enterText(inputFinder, '/get_tile_basic_info');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(snackbars.last.message, contains('tile_id: oldWorld|P1|2|3'));
      expect(snackbars.last.message, contains('province_id: oldWorld|P1'));
      expect(events, isEmpty);
    });

    testWidgets('/list_players appends output and emits no session events', (
      tester,
    ) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <SessionCommandEvent>[];
      final eventSub = bus.on<SessionCommandEvent>().listen(events.add);
      addTearDown(eventSub.cancel);
      final snackbars = <ShowSnackBarEvent>[];
      final snackbarSub = bus.on<ShowSnackBarEvent>().listen(snackbars.add);
      addTearDown(snackbarSub.cancel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleOverlayPanel(
              bus: bus,
              humanPlayerId: 'human_1',
              readOnlyContextProvider: () => DebugConsoleReadOnlyContext(
                players: [
                  const DebugConsolePlayerSnapshot(
                    id: 'p1',
                    displayName: 'One',
                    isHuman: true,
                    capitalProvinceId: 'r|P9',
                  ),
                ],
              ),
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final inputFinder = find.byKey(
        const ValueKey<String>('debug-console-input'),
      );
      await tester.enterText(inputFinder, '/list_players');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(snackbars.last.message, contains('players_count: 1'));
      expect(snackbars.last.message, contains('player_id: p1'));
      expect(events, isEmpty);
    });
  });

  group('DebugConsoleOverlayPanel dark editorial-monocle chrome (Refs #2914 '
      'S3 + S8)', () {
    Future<void> pumpPanel(
      WidgetTester tester, {
      required AppEventBus bus,
      VoidCallback? onClose,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleOverlayPanel(
              bus: bus,
              humanPlayerId: 'human_1',
              readOnlyContextProvider: () =>
                  const DebugConsoleReadOnlyContext(),
              onClose: onClose ?? () {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'panel close affordance is a CtIconAction (no Material IconButton)',
      (tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        await pumpPanel(tester, bus: bus);

        final closeFinder = find.byKey(
          DebugConsoleOverlayPanel.closeButtonKey,
        );
        expect(
          closeFinder,
          findsOneWidget,
          reason:
              'Refs #2914 S8 requires the catalog CtIconAction primitive '
              '(not the banned Material IconButton) for the close affordance.',
        );
        // The keyed widget itself must be the CtIconAction catalog primitive.
        expect(
          tester.widget(closeFinder),
          isA<CtIconAction>(),
        );
        expect(
          find.descendant(
            of: find.byType(DebugConsoleOverlayPanel),
            matching: find.byType(CtIconAction),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(DebugConsoleOverlayPanel),
            matching: find.byType(IconButton),
          ),
          findsNothing,
          reason:
              'Banned Material IconButton must not appear in the panel '
              'subtree (Refs #2914 S8 / SPEC/ui/pixel-art-ui-catalog.md '
              '\u00a7 Material design ban).',
        );
      },
    );

    testWidgets(
      'tapping the CtIconAction close affordance invokes onClose',
      (tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        var closeCount = 0;
        await pumpPanel(tester, bus: bus, onClose: () => closeCount += 1);

        await tester.tap(
          find.byKey(DebugConsoleOverlayPanel.closeButtonKey),
        );
        await tester.pump();

        expect(closeCount, 1);
      },
    );

    testWidgets(
      'header title text style colour resolves to '
      'EditorialMonoclePalette.fg (no Material Colors.white)',
      (tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        await pumpPanel(tester, bus: bus);

        final headerText = tester.widget<Text>(
          find.text('Debug Console'),
        );
        expect(headerText.style?.color, EditorialMonoclePalette.fg);
        expect(headerText.style?.fontWeight, FontWeight.w700);
      },
    );

    testWidgets(
      'TextField input style colour resolves to '
      'EditorialMonoclePalette.fg (no Material Colors.white)',
      (tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        await pumpPanel(tester, bus: bus);

        final input = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('debug-console-input')),
        );
        expect(input.style?.color, EditorialMonoclePalette.fg);
      },
    );

    testWidgets(
      'TextField hint style colour resolves to EditorialMonoclePalette.muted '
      'with the documented hint alpha (no Material Colors.white)',
      (tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        await pumpPanel(tester, bus: bus);

        final input = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('debug-console-input')),
        );
        final hintColor = input.decoration?.hintStyle?.color;
        final expectedHint = EditorialMonoclePalette.muted.withValues(
          alpha: DebugConsoleOverlayPanel.hintTextAlpha,
        );
        expect(hintColor, expectedHint);
      },
    );

    testWidgets(
      'TextField fill colour resolves to EditorialMonoclePalette.dialogScrim',
      (tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        await pumpPanel(tester, bus: bus);

        final input = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('debug-console-input')),
        );
        expect(input.decoration?.filled, isTrue);
        expect(
          input.decoration?.fillColor,
          EditorialMonoclePalette.dialogScrim,
        );
      },
    );

    testWidgets(
      'outer Material surface colour resolves to '
      'EditorialMonoclePalette.bgDeep at the documented panel alpha '
      '(no Material Colors.black)',
      (tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        await pumpPanel(tester, bus: bus);

        final panelMaterial = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(DebugConsoleOverlayPanel),
                matching: find.byType(Material),
              )
              .first,
        );
        final expectedSurface = EditorialMonoclePalette.bgDeep.withValues(
          alpha: DebugConsoleOverlayPanel.panelBackgroundAlpha,
        );
        expect(panelMaterial.color, expectedSurface);
      },
    );
  });
}
