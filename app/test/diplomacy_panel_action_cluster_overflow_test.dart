// Overflow / wrap cases for the wide-row diplomacy action cluster
// (Refs #3621 / #4720 Slice F). SPEC/ui/diplomacy-panel.md § Responsive layout.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_constants.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'diplomacy_panel_action_cluster_test_support.dart';

Future<void> _pumpBuilt(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  suppressLogsForTests();

  setUp(AppEventBus.reset);

  Future<void> bindSurface(WidgetTester tester, {Size? size}) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(size ?? const Size(1000, 1600));
  }

  List<Rect> actionRects(WidgetTester tester, Key bodyKey) {
    final Finder buttons = find.descendant(
      of: find.byKey(bodyKey),
      matching: find.byType(CtNinePatchButton),
    );
    final int count = buttons.evaluate().length;
    return <Rect>[
      for (int i = 0; i < count; i++) tester.getRect(buttons.at(i)),
    ];
  }

  group('Diplomacy wide action cluster (Refs #3621)', () {
    testWidgets(
      'wide but width-constrained: cluster fills runs left-to-right and '
      'wraps without forming a vertical column',
      (WidgetTester tester) async {
        // 600 dp > kDiplomacyRowNarrowMaxWidth (wide variant) but narrow
        // enough that the full GP matrix cannot fit on one run.
        await bindSurface(tester, size: const Size(600, 1600));
        await tester.pumpWidget(
          diplomacyActionClusterPanelHost(viewportSize: const Size(600, 1200)),
        );
        await _pumpBuilt(tester);

        final Key bodyKey = ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2');
        final List<Rect> rects = actionRects(tester, bodyKey);
        expect(rects.length, greaterThanOrEqualTo(3));

        final Map<double, List<Rect>> runs = diplomacyActionClusterRunsByTop(
          rects,
        );

        // Wrapping occurred: more than one run is present.
        expect(
          runs.length,
          greaterThanOrEqualTo(2),
          reason:
              'At a width-constrained wide viewport the matrix must wrap onto '
              'multiple runs.',
        );

        // Not a vertical column: the buttons do not all share one x-offset,
        // and at least one run packs two buttons side by side.
        final Set<double> allLefts = rects
            .map((Rect r) => (r.left * 2).roundToDouble() / 2)
            .toSet();
        expect(allLefts.length, greaterThanOrEqualTo(2));
        final int largestRun = runs.values
            .map((List<Rect> run) => run.length)
            .reduce((int a, int b) => a > b ? a : b);
        expect(largestRun, greaterThanOrEqualTo(2));

        // The cluster width is the available trailing region (the Align that
        // wraps the end-aligned Wrap), not a fixed dp cap.
        final Finder topRightAlign = find.descendant(
          of: find.byKey(bodyKey),
          matching: find.byWidgetPredicate(
            (Widget w) => w is Align && w.alignment == Alignment.topRight,
          ),
        );
        final double clusterWidth = tester.getRect(topRightAlign).width;

        final List<double> runTops = runs.keys.toList()..sort();
        final double globalRight = rects
            .map((Rect r) => r.right)
            .reduce((double a, double b) => a > b ? a : b);
        const double spacing = kDiplomacyActionWrapSpacing;
        const double tol = 1.0;

        for (int i = 0; i < runTops.length; i++) {
          final List<Rect> run = runs[runTops[i]]!;
          // Left-to-right within a run: lefts strictly increase.
          for (int j = 1; j < run.length; j++) {
            expect(
              run[j].left,
              greaterThan(run[j - 1].left),
              reason: 'Buttons within a run must flow left-to-right.',
            );
          }
          // End-aligned: every run's rightmost button reaches the trailing
          // edge shared across runs.
          expect(
            (run.last.right - globalRight).abs(),
            lessThanOrEqualTo(tol),
            reason:
                'Each run must be right-aligned to the shared trailing edge '
                '(WrapAlignment.end).',
          );
          // Wrap only at exhaustion: for every run except the last, the first
          // button of the next run could NOT have fit in this run's remaining
          // width — proving the wrap happened because the row width was
          // exhausted, not prematurely.
          if (i < runTops.length - 1) {
            final double runContent =
                run.fold<double>(0, (double s, Rect r) => s + r.width) +
                (run.length - 1) * spacing;
            final double nextFirstWidth = runs[runTops[i + 1]]!.first.width;
            expect(
              runContent + spacing + nextFirstWidth,
              greaterThan(clusterWidth - tol),
              reason:
                  'A non-final run that could still have fit the next button '
                  'would indicate a premature wrap (Refs #3621).',
            );
          }
        }
      },
    );

    testWidgets(
      'very wide viewport: the full action matrix collapses to a single run',
      (WidgetTester tester) async {
        // A surface far wider than the matrix lets every button share one run.
        await bindSurface(tester, size: const Size(4000, 1600));
        await tester.pumpWidget(
          diplomacyActionClusterPanelHost(viewportSize: const Size(4000, 1200)),
        );
        await _pumpBuilt(tester);

        final Key bodyKey = ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2');
        final List<Rect> rects = actionRects(tester, bodyKey);
        expect(rects.length, greaterThanOrEqualTo(3));

        final Map<double, List<Rect>> runs = diplomacyActionClusterRunsByTop(
          rects,
        );
        expect(
          runs.length,
          1,
          reason:
              'Given ample width, the default ready shortlist must share one '
              'horizontal run (Refs #4265 / #3621).',
        );
      },
    );

    testWidgets(
      'narrow (<= 500 dp): action Wrap is start-aligned (no regression to '
      'wide flow)',
      (WidgetTester tester) async {
        await bindSurface(tester);
        await tester.pumpWidget(
          diplomacyActionClusterPanelHost(viewportSize: const Size(480, 1200)),
        );
        await _pumpBuilt(tester);

        final Key bodyKey = ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2');
        expect(tester.widget(find.byKey(bodyKey)), isA<Column>());

        // Match the action cluster Wrap specifically via its normative 4 dp
        // gaps (kDiplomacyActionWrapSpacing). The relation-meter Wrap in the
        // info column (Refs #3753) is also start-aligned but carries the
        // CtSpacing gaps, so it must not be conflated with the action cluster.
        final Finder startWrap = find.descendant(
          of: find.byKey(bodyKey),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is Wrap &&
                w.alignment == WrapAlignment.start &&
                w.spacing == kDiplomacyActionWrapSpacing &&
                w.runSpacing == kDiplomacyActionWrapSpacing,
          ),
        );
        expect(startWrap, findsOneWidget);
      },
    );
  });
}
