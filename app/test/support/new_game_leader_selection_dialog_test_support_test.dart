// Smoke tests for shared NewGameLeaderSelectionDialog pump helpers (Refs #4013).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';

import 'new_game_leader_selection_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('pumpNewGameLeaderSelectionDialog opens dialog', (
    WidgetTester tester,
  ) async {
    await pumpNewGameLeaderSelectionDialog(tester);
    expect(find.byType(NewGameLeaderSelectionDialog), findsOneWidget);
    expect(find.text('Choose nations and leaders'), findsOneWidget);
  });
}
