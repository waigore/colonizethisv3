import 'package:colonizethis_app/features/game/flame/debug_console_controller.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('DebugConsoleController', () {
    testWidgets(
      'submit emits events for valid command and records output',
      (tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <SpawnDebugCivilianAtCapitalEvent>[];
      final eventSub = bus.on<SpawnDebugCivilianAtCapitalEvent>().listen(
        events.add,
      );
      addTearDown(eventSub.cancel);
      final snackbars = <ShowSnackBarEvent>[];
      final snackbarSub = bus.on<ShowSnackBarEvent>().listen(snackbars.add);
      addTearDown(snackbarSub.cancel);

      final controller = DebugConsoleController(
        bus: bus,
        humanPlayerId: 'human_1',
        onClose: () {},
      );
      addTearDown(controller.dispose);
      controller.textController.text = '/spawn_civilian explorer 2';

      final message = controller.submit();
      await tester.pump();

      expect(message, contains('Queued debug spawn'));
      expect(events, hasLength(1));
      expect(events.single.unitType, kUnitTypeExplorer);
      expect(events.single.count, 2);
      expect(controller.textController.text, isEmpty);
      expect(controller.lines, contains('> /spawn_civilian explorer 2'));
      expect(snackbars.last.message, contains('Queued debug spawn'));
      },
    );

    testWidgets(
      'submit keeps input for invalid command and emits snackbar only',
      (tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <SpawnDebugCivilianAtCapitalEvent>[];
      final eventSub = bus.on<SpawnDebugCivilianAtCapitalEvent>().listen(
        events.add,
      );
      addTearDown(eventSub.cancel);
      final snackbars = <ShowSnackBarEvent>[];
      final snackbarSub = bus.on<ShowSnackBarEvent>().listen(snackbars.add);
      addTearDown(snackbarSub.cancel);

      final controller = DebugConsoleController(
        bus: bus,
        humanPlayerId: 'human_1',
        onClose: () {},
      );
      addTearDown(controller.dispose);
      controller.textController.text = '/spawn_civilian unknown_type';

      controller.submit();
      await tester.pump();

      expect(events, isEmpty);
      expect(controller.textController.text, '/spawn_civilian unknown_type');
      expect(
        snackbars.last.message,
        'Unknown civilian type. Use explorer, builder, engineer, spy, merchant, or rail_builder.',
      );
      },
    );

    test('arrow navigation and escape callbacks are handled', () {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      var closeCount = 0;
      final controller = DebugConsoleController(
        bus: bus,
        humanPlayerId: 'human_1',
        onClose: () => closeCount += 1,
      );
      addTearDown(controller.dispose);

      controller.textController.text = '/spawn_civilian explorer 1';
      controller.submit();
      controller.textController.text = '/spawn_civilian builder 2';
      controller.submit();

      final upHandled = controller.handleKeyEvent(
        const KeyDownEvent(
          timeStamp: Duration.zero,
          physicalKey: PhysicalKeyboardKey.arrowUp,
          logicalKey: LogicalKeyboardKey.arrowUp,
        ),
      );
      expect(upHandled, isTrue);
      expect(controller.textController.text, '/spawn_civilian builder 2');

      controller.handleKeyEvent(
        const KeyDownEvent(
          timeStamp: Duration.zero,
          physicalKey: PhysicalKeyboardKey.arrowUp,
          logicalKey: LogicalKeyboardKey.arrowUp,
        ),
      );
      expect(controller.textController.text, '/spawn_civilian explorer 1');

      controller.handleKeyEvent(
        const KeyDownEvent(
          timeStamp: Duration.zero,
          physicalKey: PhysicalKeyboardKey.arrowDown,
          logicalKey: LogicalKeyboardKey.arrowDown,
        ),
      );
      expect(controller.textController.text, '/spawn_civilian builder 2');

      final escapeHandled = controller.handleKeyEvent(
        const KeyDownEvent(
          timeStamp: Duration.zero,
          physicalKey: PhysicalKeyboardKey.escape,
          logicalKey: LogicalKeyboardKey.escape,
        ),
      );
      expect(escapeHandled, isTrue);
      expect(closeCount, 1);
    });
  });
}
