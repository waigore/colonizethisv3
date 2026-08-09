// Smoke tests for shared ProductionPanel hosts (Refs #4013).

import 'package:colonizethis_app/features/game/widgets/production/production_panel.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_panel_test_support.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('buildProductionPanel hosts ProductionPanel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildProductionPanel(player: productionPanelTestFullPlayer()),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(ProductionPanel), findsOneWidget);
  });
}
