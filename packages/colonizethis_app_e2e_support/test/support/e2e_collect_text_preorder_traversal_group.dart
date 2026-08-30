// Traversal / append pins extracted from e2e_collect_text_preorder_test.dart
// (#4598 headroom).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared_bootstrap.dart';

void registerE2eCollectTextPreorderTraversalGroup() {
  testWidgets('returns siblings in left-to-right order', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KeyedSubtree(
            key: Key('root'),
            child: Row(
              children: [Text('A'), Text('B'), Text('C')],
            ),
          ),
        ),
      ),
    );
    final out = <String>[];
    e2eCollectTextPreorder(tester.element(find.byKey(const Key('root'))), out);
    expect(
      out,
      const ['A', 'B', 'C'],
      reason:
          'Sibling order must follow the widget tree (Element.visitChildren '
          'visits children in declared order), matching the left-to-right '
          'reading order encoded in the snapshot expected-text mirrors.',
    );
  });

  testWidgets('emits parent before descendants in depth-first preorder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KeyedSubtree(
            key: Key('root'),
            child: Column(
              children: [
                Text('outer-1'),
                Column(
                  children: [Text('inner-1a'), Text('inner-1b')],
                ),
                Text('outer-2'),
              ],
            ),
          ),
        ),
      ),
    );
    final out = <String>[];
    e2eCollectTextPreorder(tester.element(find.byKey(const Key('root'))), out);
    expect(
      out,
      const ['outer-1', 'inner-1a', 'inner-1b', 'outer-2'],
      reason:
          'Depth-first pre-order is the contract that the snapshot mirrors '
          'rely on: a regression to post-order (children before parent) or '
          'breadth-first would shuffle every panel-level orderedEquals match.',
    );
  });

  testWidgets('traverses non-Text widgets without contributing strings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeyedSubtree(
            key: const Key('root'),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    const Icon(Icons.check),
                    Container(
                      key: const Key('intermediate'),
                      child: const Text('inside-container'),
                    ),
                    const Text('after-container'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final out = <String>[];
    e2eCollectTextPreorder(tester.element(find.byKey(const Key('root'))), out);
    expect(
      out,
      const ['inside-container', 'after-container'],
      reason:
          'Card / Padding / Row / Icon / Container are not Text widgets and '
          'must not appear in the output list, but the helper must still '
          'descend through them so wrapped Text leaves are captured.',
    );
  });

  testWidgets('appends to pre-existing output list without clearing it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KeyedSubtree(
            key: Key('root'),
            child: Text('new-entry'),
          ),
        ),
      ),
    );
    final out = <String>['pre-existing'];
    e2eCollectTextPreorder(tester.element(find.byKey(const Key('root'))), out);
    expect(
      out,
      const ['pre-existing', 'new-entry'],
      reason:
          'The helper takes the list by reference (no return value) and '
          'appends; callers concatenate results across multiple root '
          'elements, so wiping the list would break panel-by-panel snapshot '
          'composition.',
    );
  });
}
