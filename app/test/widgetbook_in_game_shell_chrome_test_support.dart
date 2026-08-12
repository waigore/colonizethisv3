// Pump helpers for in-game shell chrome Widgetbook story tests (Refs #4305).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'widgetbook_test_harness.dart';

Future<void> pumpWidgetbookStory(
  WidgetTester tester,
  List<WidgetbookNode> directories, {
  required String folder,
  required String useCase,
  Duration? extra,
  bool resetTree = false,
}) async {
  if (resetTree) {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }
  final story = findWidgetbookUseCase(
    directories,
    folderName: folder,
    useCaseName: useCase,
  );
  await tester.pumpWidget(
    story.builder(tester.element(find.byType(View))),
  );
  await tester.pump();
  if (extra != null) {
    await tester.pump(extra);
  }
}

Future<T> pumpWidgetbookStoryAs<T extends Widget>(
  WidgetTester tester,
  List<WidgetbookNode> directories, {
  required String folder,
  required String useCase,
  Duration? extra,
}) async {
  await pumpWidgetbookStory(
    tester,
    directories,
    folder: folder,
    useCase: useCase,
    extra: extra,
  );
  return tester.widget<T>(find.byType(T));
}

Future<void> expectWidgetbookStoriesMount(
  WidgetTester tester,
  List<WidgetbookNode> directories, {
  required String folder,
  required List<String> useCases,
  required Type widgetType,
  Duration? extra,
}) async {
  for (final name in useCases) {
    await pumpWidgetbookStory(
      tester,
      directories,
      folder: folder,
      useCase: name,
      extra: extra,
    );
    expect(find.byType(widgetType), findsOneWidget);
  }
}
