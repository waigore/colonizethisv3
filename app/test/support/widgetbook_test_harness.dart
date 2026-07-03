// Shared Widgetbook story lookup and viewport pump helpers for
// `widgetbook_*_test.dart` pins. Refs #3847.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

/// Locate the single use-case with [useCaseName] inside the
/// [WidgetbookFolder] whose name matches [folderName], failing with a
/// readable matcher message if the folder or use case is missing.
WidgetbookUseCase findWidgetbookUseCase(
  List<WidgetbookNode> directories, {
  required String folderName,
  required String useCaseName,
}) {
  final folder = directories.whereType<WidgetbookFolder>().firstWhere(
    (folder) => folder.name == folderName,
    orElse: () =>
        fail('Missing Widgetbook folder: $folderName (got: $directories)'),
  );
  final children = folder.children ?? const <WidgetbookNode>[];
  return children.whereType<WidgetbookUseCase>().firstWhere(
    (uc) => uc.name == useCaseName,
    orElse: () => fail(
      'Missing use case "$useCaseName" in folder "$folderName" '
      '(got: ${children.map((c) => c.name).toList()})',
    ),
  );
}

/// Pumps [useCase] inside a [MaterialApp] with [size] bound on both the test
/// surface and an explicit [MediaQuery] (matches production mobileViewport).
Future<void> pumpWidgetbookUseCaseAtSize(
  WidgetTester tester,
  WidgetbookUseCase useCase, {
  Size size = const Size(360, 640),
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: Builder(builder: (BuildContext ctx) => useCase.builder(ctx)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}
