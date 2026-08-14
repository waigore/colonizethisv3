// Pump helpers for AppEventHandler widget tests (Refs #4352).

import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

AppEventHandler buildTestAppEventHandler({
  required AppEventBus bus,
  required GlobalKey<NavigatorState> navigatorKey,
  Map<String, Widget Function(BuildContext, Map<String, Object?>?)>?
  dialogBuilders,
  Map<String, Widget Function(BuildContext, Map<String, Object?>?)>?
  panelBuilders,
  void Function(ShowSnackBarEvent event)? onShowSnackBar,
  void Function(DismissOverlayEvent event)? onDismissOverlay,
}) {
  return AppEventHandler(
    bus: bus,
    navigatorKey: navigatorKey,
    dialogBuilders:
        dialogBuilders ??
        {
          'test_dialog': (ctx, params) =>
              Material(child: Text('dialog:${params?['id'] ?? 'default'}')),
        },
    panelBuilders:
        panelBuilders ??
        {
          'test_panel': (ctx, params) =>
              Material(child: Text('panel:${params?['id'] ?? 'default'}')),
        },
    onShowSnackBar: onShowSnackBar,
    onDismissOverlay: onDismissOverlay,
  );
}

Future<void> pumpAppEventHandlerEmitButton(
  WidgetTester tester, {
  required GlobalKey<NavigatorState> navigatorKey,
  required String label,
  required VoidCallback onPressed,
  RouteFactory? onGenerateRoute,
  Widget? home,
  List<Override> overrides = const <Override>[],
}) async {
  await tester.pumpWidget(
    buildAppShell(
      navigatorKey: navigatorKey,
      onGenerateRoute: onGenerateRoute,
      overrides: overrides,
      child:
          home ??
          Builder(
            builder: (ctx) =>
                TextButton(onPressed: onPressed, child: Text(label)),
          ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapAppEventHandlerLabel(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}
