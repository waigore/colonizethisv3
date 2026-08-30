// Widgetbook pin for Tech Tree → Tree dialog — in-progress finish line
// (Refs #4511). SPEC/ui/tech-tree-widget.md § Widgetbook.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_finish_line.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';

import 'app_shell_harness.dart';
import 'widgetbook_test_harness.dart';

const String _kFolderName = 'Tech Tree';
const String _kUseCaseName = 'Tree dialog — in-progress finish line';

Future<void> _pumpUseCase(
  WidgetTester tester,
  WidgetbookUseCase useCase,
) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Builder(builder: (BuildContext ctx) => useCase.builder(ctx)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'use case is wired and seated Saw Mill dialog shows Completes next turn',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(900, 900));

      final useCase = findWidgetbookUseCase(
        techTreeDirectories,
        folderName: _kFolderName,
        useCaseName: _kUseCaseName,
      );
      await _pumpUseCase(tester, useCase);
      expect(tester.takeException(), isNull);

      final node = find.text(techDisplayName(kTechIdSawMill)).first;
      await tester.ensureVisible(node);
      await tester.tap(node);
      await tester.pumpAndSettle();

      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.byKey(TechTreeFinishLine.lineKey), findsOneWidget);
      expect(find.textContaining('Completes next turn'), findsOneWidget);
    },
  );
}
