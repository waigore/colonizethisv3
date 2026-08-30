// Shared Widgetbook story helpers for DLG60001 / SHEL30001 (Refs #2867 / #4642).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

/// requires. Renaming or removing one must fail the inventory test below.
const List<String> kNextTurnConfirmationUseCaseNames = <String>[
  'Default — turn 1',
  'Mid-game — turn 42',
  'Warning — idle civilians',
  'Staged — one family',
  'Staged — multi-family',
];

/// Normative inventory of the new SHEL30001 stories that issue #2867 S13
/// requires (one story per phase index `0..4` + the failure-state card).
const List<String> kGameInitializingUseCaseNames = <String>[
  'Progress — phase 0 (Old World)',
  'Progress — phase 1 (New World)',
  'Progress — phase 2 (Warp linking)',
  'Progress — phase 3 (Building world)',
  'Progress — phase 4 (Saving)',
  'Error — danger-bordered retry card',
];

WidgetbookFolder widgetbookFolderNamed(
  List<WidgetbookNode> directories, {
  required String folderName,
}) {
  return directories.whereType<WidgetbookFolder>().firstWhere(
    (folder) => folder.name == folderName,
    orElse: () => fail('Missing Widgetbook folder: $folderName'),
  );
}

Future<void> pumpWidgetbookStory(
  WidgetTester tester,
  WidgetbookUseCase useCase,
) async {
  await tester.pumpWidget(Builder(builder: useCase.builder));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}
