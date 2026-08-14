// Pump/listen helpers for DebugConsoleOverlayPanel widget tests (Refs #4352).

import 'package:colonizethis_app/features/game/flame/overlays/debug_console_overlay_panel.dart';
import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

const debugConsoleInputKey = ValueKey<String>('debug-console-input');

AppEventBus debugConsoleBus() {
  final bus = AppEventBus.create();
  addTearDown(bus.dispose);
  return bus;
}

List<T> listenDebugEvents<T extends AppEvent>(AppEventBus bus) {
  final events = <T>[];
  final sub = bus.on<T>().listen(events.add);
  addTearDown(sub.cancel);
  return events;
}

Future<void> pumpDebugConsolePanel(
  WidgetTester tester, {
  required AppEventBus bus,
  VoidCallback? onClose,
  DebugConsoleReadOnlyContext Function()? readOnlyContextProvider,
}) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: DebugConsoleOverlayPanel(
          bus: bus,
          humanPlayerId: 'human_1',
          readOnlyContextProvider:
              readOnlyContextProvider ??
              () => const DebugConsoleReadOnlyContext(),
          onClose: onClose ?? () {},
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> submitDebugCommand(WidgetTester tester, String command) async {
  await tester.enterText(find.byKey(debugConsoleInputKey), command);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}
