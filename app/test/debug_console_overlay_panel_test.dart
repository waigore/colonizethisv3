import 'dart:async';

import 'package:colonizethis_app/features/game/flame/debug_console_overlay_panel.dart';
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
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleOverlayPanel(
              bus: bus,
              humanPlayerId: 'human_1',
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
      expect(closed, isFalse);
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
  });
}
