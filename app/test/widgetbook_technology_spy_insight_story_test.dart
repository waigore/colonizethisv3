// Widget test pin for Tech Tree spy-insight Widgetbook use cases (Refs #4457).
// SPEC: SPEC/ui/technology-panel.md § Widgetbook.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/research_slot_turn_preview_view.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_panel.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'app_shell_harness.dart';
import 'widgetbook_test_harness.dart';

const String _kFolderName = 'Tech Tree';

Future<void> _pumpUseCase(WidgetTester tester, String useCaseName) async {
  final useCase = findWidgetbookUseCase(
    techTreeDirectories,
    folderName: _kFolderName,
    useCaseName: useCaseName,
  );
  await tester.pumpWidget(
    buildAppShell(
      child: Builder(builder: (BuildContext ctx) => useCase.builder(ctx)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Technology spy-insight Widgetbook stories (Refs #4457)', () {
    testWidgets('spy insight and funding None use cases are wired', (
      WidgetTester tester,
    ) async {
      for (final name in <String>[
        'Slots — spy insight (one rival)',
        'Slots — spy insight (two rivals)',
        'Slots — funding None',
      ]) {
        final useCase = findWidgetbookUseCase(
          techTreeDirectories,
          folderName: _kFolderName,
          useCaseName: name,
        );
        expect(useCase.builder, isNotNull, reason: name);
      }
    });

    testWidgets(
      'one-rival story mounts TechnologyPanel with anticipated RP delta',
      (WidgetTester tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(900, 900));
        await _pumpUseCase(tester, 'Slots — spy insight (one rival)');
        expect(tester.takeException(), isNull);
        expect(find.byType(TechnologyPanel), findsOneWidget);
        expect(
          find.byKey(ResearchSlotTurnPreviewView.rpDeltaKey(0)),
          findsOneWidget,
        );
      },
    );

    testWidgets('funding None story hides the RP delta', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(900, 900));
      await _pumpUseCase(tester, 'Slots — funding None');
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(ResearchSlotTurnPreviewView.rpDeltaKey(0)),
        findsNothing,
      );
    });
  });
}
