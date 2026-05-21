// Pins the contract of `e2eCollectTextPreorder` — the helper that backs
// `collectTextPreorder` in `app/integration_test/e2e_helpers.dart` and is
// consumed by the snapshot-text assertions in
// `new_game_full_turn_e2e_test.dart` (civilian, naval, production panels) and
// `new_game_capital_panel_e2e_test.dart` (province panel) via
// `orderedEquals(expected)` comparisons against
// `civilianUnitsPanelExpectedTexts` / `navalPanelExpectedTexts` /
// `productionPanelWideExpectedTexts` / `provincePanelWideLayoutExpectedTexts`.
//
// Those expected-text mirrors are *order-sensitive*: they list strings in
// the deterministic order they should appear in the rendered widget tree.
// If the collector regressed to anything other than depth-first pre-order
// (e.g. post-order, breadth-first, reverse sibling order) or stopped
// filtering empty / null `Text.data` values, the affected E2E scenarios
// would suddenly fail with confusing ordering diffs even when the panels
// rendered correctly. There is no existing direct contract test for this
// helper; the smoke suite only exercises sibling helpers
// (`e2e_test_shared_smoke_test.dart`).
//
// Coverage layers:
//   - Empty subtree (no Text descendants) — out list stays untouched.
//   - Single `Text('foo')` — captured exactly once.
//   - `Text('')` and `Text.rich(...)` — skipped (null/empty `data` guard).
//   - Mixed siblings — captured in left-to-right pre-order.
//   - Nested subtree — parent before descendants; depth-first recursion.
//   - Non-`Text` widgets interleaved — traversed without contributing strings.
//   - Output list mutation — pre-existing entries preserved; new entries
//     appended.
//
// SPEC:
//   - `SPEC/program/e2e-integration-tests.md` § Local run (snapshot mirrors).
//   - Issue #2336 (Refs): shared E2E helpers and snapshot-text assertions.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared_bootstrap.dart';

void main() {
  suppressLogsForTests();

  testWidgets('returns without appending when subtree has no Text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox(key: Key('root'))),
      ),
    );
    final out = <String>[];
    e2eCollectTextPreorder(tester.element(find.byKey(const Key('root'))), out);
    expect(
      out,
      isEmpty,
      reason:
          'Subtrees free of Text widgets must leave the output list untouched '
          'so callers can compose multiple roots without spurious entries.',
    );
  });

  testWidgets('captures the single non-empty Text.data exactly once', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KeyedSubtree(key: Key('root'), child: Text('hello')),
        ),
      ),
    );
    final out = <String>[];
    e2eCollectTextPreorder(tester.element(find.byKey(const Key('root'))), out);
    expect(
      out,
      const ['hello'],
      reason:
          'A single non-empty Text under the root must be captured exactly '
          'once — the snapshot mirrors compare with orderedEquals so any '
          'duplication would silently fail E2E assertions.',
    );
  });

  testWidgets('skips Text widgets whose data is empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KeyedSubtree(
            key: Key('root'),
            child: Column(
              children: [Text(''), Text('keep'), Text('')],
            ),
          ),
        ),
      ),
    );
    final out = <String>[];
    e2eCollectTextPreorder(tester.element(find.byKey(const Key('root'))), out);
    expect(
      out,
      const ['keep'],
      reason:
          'Empty Text.data entries must be filtered so panels using "" as a '
          'layout spacer do not bleed extra rows into the orderedEquals '
          'comparison.',
    );
  });

  testWidgets('skips Text.rich widgets (null data branch)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeyedSubtree(
            key: const Key('root'),
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    children: const [
                      TextSpan(text: 'rich-span-a'),
                      TextSpan(text: 'rich-span-b'),
                    ],
                  ),
                ),
                const Text('plain'),
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
      const ['plain'],
      reason:
          'Text.rich leaves `Text.data == null` and feeds children through '
          '`textSpan`; the helper must skip the null-data branch and capture '
          'only the plain Text sibling. The snapshot mirrors do not expand '
          'rich-span children, so capturing them here would invert the '
          'invariant.',
    );
  });

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
