// Smoke pins for screen_spec_acceptance_test_support (Refs #4013).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screen_spec_acceptance_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('buildScreenSpecMainMenu hosts CtMainMenu', (tester) async {
    await tester.pumpWidget(
      buildScreenSpecMainMenu(
        onQuickStart: () {},
        onNewGame: () {},
        onLoadGame: () {},
        onSettings: () {},
        onQuit: () {},
      ),
    );
    expect(find.byType(CtMainMenu), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme, AppThemes.colonial);
  });

  testWidgets('pumpScreenSpecMainMenuAtSize sets surface size', (tester) async {
    await pumpScreenSpecMainMenuAtSize(
      tester,
      size: const Size(360, 640),
      variant: MainMenuVariant.plain,
    );
    expect(find.byType(CtMainMenu), findsOneWidget);
  });
}
