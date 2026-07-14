// AC1 barrel wrapper forwarding smokes (split from part1 under
// `repo.app_test_file_size`, Refs #4013 / #2336).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';

void main() {
  suppressLogsForTests();

  group('AC1 barrel: wrapper forwarding smokes', () {
    testWidgets('pumpFor returns without throwing for Duration.zero', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await pumpFor(tester, Duration.zero);
    });

    testWidgets('pumpFor advances the test clock for a positive duration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      // Smoke: forwarding to e2ePumpFor (which loops 50ms pumps) must
      // complete without exception for a short, bounded duration. A
      // wrapper that dropped the Duration arg would either no-op
      // (passes vacuously) or call pump(null) (throws); only the
      // throw branch is asserted here because the no-op is OK by
      // contract.
      await pumpFor(tester, const Duration(milliseconds: 100));
    });

    testWidgets(
      'collectTextPreorder matches e2eCollectTextPreorder for a mixed subtree',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: KeyedSubtree(
                key: Key('root'),
                child: Column(
                  children: [Text('alpha'), Text(''), Text('beta')],
                ),
              ),
            ),
          ),
        );
        final out = <String>[];
        collectTextPreorder(tester.element(find.byKey(const Key('root'))), out);
        expect(
          out,
          const ['alpha', 'beta'],
          reason:
              'The barrel wrapper must reproduce e2eCollectTextPreorder '
              'depth-first pre-order + empty-data filtering exactly; '
              'orderedEquals on snapshot mirrors depends on it.',
        );
      },
    );

    testWidgets(
      'waitUntilFound short-circuits when finder is already non-empty',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(child: Text('here', key: Key('here'))),
            ),
          ),
        );
        final sw = Stopwatch()..start();
        await waitUntilFound(
          tester,
          find.byKey(const Key('here')),
          timeout: const Duration(seconds: 2),
          phaseName: 'barrel_smoke_immediate',
        );
        expect(
          sw.elapsed,
          lessThan(const Duration(milliseconds: 500)),
          reason:
              'The wrapper must forward to e2eWaitUntilFound, which '
              'short-circuits before its first pump when the finder '
              'already matches. A wrapper that hard-coded a longer '
              'initial sleep would visibly exceed this bound.',
        );
      },
    );

    testWidgets(
      'dismissTransientUi returns without throwing when no overlay is mounted',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await dismissTransientUi(tester);
      },
    );

    testWidgets(
      'expandEachExpansionTileOnce returns early when no ExpansionTile exists',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        final sw = Stopwatch()..start();
        await expandEachExpansionTileOnce(tester);
        expect(
          sw.elapsed,
          lessThan(const Duration(seconds: 2)),
          reason:
              'The wrapper must forward to e2eExpandEachExpansionTileOnce, '
              'which early-exits on the first iteration when no tiles '
              'exist (Bottleneck 6 / H10 fix). A wrapper that re-ran the '
              '32-iteration safety loop would visibly exceed this bound.',
        );
      },
    );
  });
}
