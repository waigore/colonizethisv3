// Pins the corrected behavior of `e2eExpandEachExpansionTileOnce`: detect
// expansion via [RotationTransition] state (Material `ExpansionTile` keeps
// `Icons.expand_more` mounted at all times, so the previous icon-presence
// check was a 26 s no-op). The helper must now actually expand collapsed
// tiles and short-circuit on already-expanded ones (Refs GitHub #2336 H10
// / Bottleneck 6 fix).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  suppressLogsForTests();

  testWidgets('e2eExpandEachExpansionTileOnce returns immediately when no tiles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final sw = Stopwatch()..start();
    await e2eExpandEachExpansionTileOnce(tester);
    expect(
      sw.elapsed < const Duration(milliseconds: 100),
      isTrue,
      reason:
          'No-tile calls must short-circuit before pumping any frame so the '
          'helper does not amplify caller cost when nothing needs expanding.',
    );
  });

  testWidgets('e2eExpansionTileIsExpanded reflects collapsed and expanded state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [
              ExpansionTile(
                title: Text('Fleet 1'),
                children: [ListTile(title: Text('child-1'))],
              ),
              ExpansionTile(
                title: Text('Fleet 2'),
                initiallyExpanded: true,
                children: [ListTile(title: Text('child-2'))],
              ),
            ],
          ),
        ),
      ),
    );
    final tiles = find.byType(ExpansionTile).evaluate().toList();
    expect(tiles.length, 2);
    expect(
      e2eExpansionTileIsExpanded(tiles[0]),
      isFalse,
      reason: 'Collapsed tile RotationTransition.turns must read < 0.4.',
    );
    expect(
      e2eExpansionTileIsExpanded(tiles[1]),
      isTrue,
      reason: 'Initially expanded tile RotationTransition.turns must read >= 0.4.',
    );
  });

  testWidgets('e2eExpandEachExpansionTileOnce expands a single collapsed tile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [
              ExpansionTile(
                title: Text('Fleet 1'),
                children: [ListTile(title: Text('child-1'))],
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      find.text('child-1'),
      findsNothing,
      reason:
          'Collapsed ExpansionTile removes its children from the tree until '
          'expanded, so the child text must not be findable up front.',
    );

    final sw = Stopwatch()..start();
    await e2eExpandEachExpansionTileOnce(tester);
    expect(
      sw.elapsed < const Duration(seconds: 2),
      isTrue,
      reason:
          'A single collapsed tile must expand well inside the per-tile budget. '
          'The previous helper burned ~26 s per call by toggling the tile 32 '
          'times when the icon-presence check never short-circuited.',
    );

    final tilesAfter = find.byType(ExpansionTile).evaluate().toList();
    expect(tilesAfter.length, 1);
    expect(
      e2eExpansionTileIsExpanded(tilesAfter.single),
      isTrue,
      reason:
          'Helper must leave the previously collapsed tile expanded once it '
          'returns (Refs GitHub #2336 H10).',
    );
    expect(
      find.text('child-1'),
      findsOneWidget,
      reason:
          'Child content must be visible once the helper has finished its '
          'bounded expand wait.',
    );
  });

  testWidgets('e2eExpandEachExpansionTileOnce expands every collapsed tile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [
              ExpansionTile(
                title: Text('Fleet 1'),
                children: [ListTile(title: Text('child-1'))],
              ),
              ExpansionTile(
                title: Text('Fleet 2'),
                children: [ListTile(title: Text('child-2'))],
              ),
              ExpansionTile(
                title: Text('Fleet 3'),
                children: [ListTile(title: Text('child-3'))],
              ),
            ],
          ),
        ),
      ),
    );

    await e2eExpandEachExpansionTileOnce(tester);

    final tilesAfter = find.byType(ExpansionTile).evaluate().toList();
    expect(tilesAfter.length, 3);
    for (final tile in tilesAfter) {
      expect(
        e2eExpansionTileIsExpanded(tile),
        isTrue,
        reason:
            'Every collapsed ExpansionTile must be expanded so naval/civilian '
            'fleet rows render their inner Move/Split / ship-count rows (Refs '
            'GitHub #2336 H10 fleet panel expand).',
      );
    }
    expect(find.text('child-1'), findsOneWidget);
    expect(find.text('child-2'), findsOneWidget);
    expect(find.text('child-3'), findsOneWidget);
  });

  testWidgets(
    'e2eExpandEachExpansionTileOnce no-ops when every tile is already expanded',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                ExpansionTile(
                  title: Text('Fleet 1'),
                  initiallyExpanded: true,
                  children: [ListTile(title: Text('child-1'))],
                ),
                ExpansionTile(
                  title: Text('Fleet 2'),
                  initiallyExpanded: true,
                  children: [ListTile(title: Text('child-2'))],
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('child-1'), findsOneWidget);
      expect(find.text('child-2'), findsOneWidget);

      final sw = Stopwatch()..start();
      await e2eExpandEachExpansionTileOnce(tester);
      expect(
        sw.elapsed < const Duration(milliseconds: 200),
        isTrue,
        reason:
            'Already-expanded tiles must short-circuit the outer safety loop '
            'without paying the per-tile expand budget for nothing. The '
            'previous helper paid 32 * 800 ms (~26 s) here because the '
            'icon-presence check never detected the expanded state.',
      );

      final tilesAfter = find.byType(ExpansionTile).evaluate().toList();
      expect(tilesAfter.length, 2);
      for (final tile in tilesAfter) {
        expect(
          e2eExpansionTileIsExpanded(tile),
          isTrue,
          reason:
              'Tiles that were already expanded must stay expanded — the '
              'helper must not toggle them shut.',
        );
      }
      expect(find.text('child-1'), findsOneWidget);
      expect(find.text('child-2'), findsOneWidget);
    },
  );

  testWidgets(
    'e2eExpandEachExpansionTileOnce expands only collapsed tiles in a mixed list',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                ExpansionTile(
                  title: Text('Already open'),
                  initiallyExpanded: true,
                  children: [ListTile(title: Text('open-child'))],
                ),
                ExpansionTile(
                  title: Text('Closed one'),
                  children: [ListTile(title: Text('closed-child'))],
                ),
              ],
            ),
          ),
        ),
      );

      await e2eExpandEachExpansionTileOnce(tester);

      final tilesAfter = find.byType(ExpansionTile).evaluate().toList();
      expect(tilesAfter.length, 2);
      for (final tile in tilesAfter) {
        expect(
          e2eExpansionTileIsExpanded(tile),
          isTrue,
          reason:
              'Both tiles must end expanded — the already-open tile is '
              'skipped, the closed one is tapped once.',
        );
      }
      expect(find.text('open-child'), findsOneWidget);
      expect(find.text('closed-child'), findsOneWidget);
    },
  );
}
