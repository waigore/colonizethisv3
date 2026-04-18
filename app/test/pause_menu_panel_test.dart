import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/features/game/widgets/pause_menu_panel.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  testWidgets('Debug log emits ClosePanelEvent then NavigateToRouteEvent', (
    WidgetTester tester,
  ) async {
    final bus = AppEventBus.create();
    final events = <AppEvent>[];
    bus.stream.listen(events.add);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PauseMenuPanel(bus: bus),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Debug log'));
    await tester.pumpAndSettle();

    expect(events.length, greaterThanOrEqualTo(2));
    final closeIndex = events.indexWhere((e) => e is ClosePanelEvent);
    final navIndex = events.indexWhere(
      (e) => e is NavigateToRouteEvent && e.route == Routes.debugLog,
    );
    expect(closeIndex, isNonNegative);
    expect(navIndex, isNonNegative);
    expect(closeIndex, lessThan(navIndex));
  });

  testWidgets('Resume emits only ClosePanelEvent', (WidgetTester tester) async {
    final bus = AppEventBus.create();
    final events = <AppEvent>[];
    bus.stream.listen(events.add);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PauseMenuPanel(bus: bus),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();

    expect(events, hasLength(1));
    expect(events.single, isA<ClosePanelEvent>());
  });
}
