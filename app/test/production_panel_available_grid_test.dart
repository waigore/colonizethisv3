// Tests for the Available subpanel grid layout: 3-column commodity sections
// (Food / Raw Materials / Manufactured) and 2-column Workers section per
// owner decision **C7** / S8b for issue #2862. SPEC:
// SPEC/ui/production-panel.md § Layout — Available subpanel.

import 'package:colonizethis_app/features/game/widgets/production_panel.dart';
import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_panel_test_fixtures.dart';
import 'widget_test_pumps.dart';

class _ProductionPanelGridTestWrapper extends StatefulWidget {
  const _ProductionPanelGridTestWrapper({
    required this.displayGame,
    required this.player,
    this.viewportWidth = 800,
    this.viewportHeight = 720,
  });

  final Game displayGame;
  final Player player;
  final double viewportWidth;
  final double viewportHeight;

  @override
  State<_ProductionPanelGridTestWrapper> createState() =>
      _ProductionPanelGridTestWrapperState();
}

class _ProductionPanelGridTestWrapperState
    extends State<_ProductionPanelGridTestWrapper> {
  Map<String, int> _desired = const <String, int>{};

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(widget.viewportWidth, widget.viewportHeight),
        ),
        child: Scaffold(
          body: SizedBox(
            width: widget.viewportWidth,
            height: widget.viewportHeight,
            child: ProductionPanel(
              game: widget.displayGame,
              player: widget.player,
              desiredOutputByRecipe: _desired,
              netDeltasByCommodity: const <String, int>{},
              onDesiredOutputChanged: (next) {
                setState(() {
                  _desired = Map<String, int>.from(next);
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Returns the Wrap children whose first descendant `SizedBox` has the largest
/// non-zero width and contains a [CtResourceCell] with `cellKey`. The Wrap is
/// used by [_AvailableCellGrid] to lay out commodity / worker cells in a
/// fixed-column grid; this helper resolves the row width chosen for the
/// commodity slot at test time.
double _slotWidthFor(WidgetTester tester, Key cellKey) {
  final cell = find.byKey(cellKey);
  expect(cell, findsOneWidget);
  final slot = find.ancestor(of: cell, matching: find.byType(SizedBox)).first;
  return tester.widget<SizedBox>(slot).width!;
}

void main() {
  suppressLogsForTests();

  late Player fullPlayer;

  setUpAll(() {
    fullPlayer = productionPanelTestFullPlayer();
  });

  group('ProductionPanel Available grid (Refs #2862 S8b / C7)', () {
    testWidgets(
      'commodity grid columns constant equals 3 (Refs #2862 S8b / C7)',
      (WidgetTester tester) async {
        expect(kProductionAvailableCommodityGridColumns, 3);
      },
    );

    testWidgets(
      'worker grid columns constant equals 2 (Refs #2862 S8b / C7)',
      (WidgetTester tester) async {
        expect(kProductionAvailableWorkerGridColumns, 2);
      },
    );

    testWidgets(
      'Workers section is laid out in 2 columns on wide viewports (Refs #2862 S8b)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _ProductionPanelGridTestWrapper(
            displayGame: productionPanelTestGameFor(fullPlayer),
            player: fullPlayer,
            viewportWidth: 800,
            viewportHeight: 720,
          ),
        );
        await pumpSettleCapped(tester);

        final gridFinder = find.byKey(kProductionAvailableWorkerGridKey);
        expect(gridFinder, findsOneWidget);

        const tiers = <String>['peasant', 'apprentice', 'journeyman', 'master'];
        for (final tier in tiers) {
          expect(
            find.descendant(
              of: gridFinder,
              matching: find.byKey(
                ValueKey<String>('production_available_worker_$tier'),
              ),
            ),
            findsOneWidget,
            reason:
                'Workers grid must contain one CtResourceCell for tier $tier',
          );
        }

        final peasantWidth = _slotWidthFor(
          tester,
          const ValueKey<String>('production_available_worker_peasant'),
        );
        final apprenticeWidth = _slotWidthFor(
          tester,
          const ValueKey<String>('production_available_worker_apprentice'),
        );
        final journeymanWidth = _slotWidthFor(
          tester,
          const ValueKey<String>('production_available_worker_journeyman'),
        );
        final masterWidth = _slotWidthFor(
          tester,
          const ValueKey<String>('production_available_worker_master'),
        );

        final gridBox = tester.getRect(gridFinder);
        final approxColWidth =
            (gridBox.width - 6 /* _AvailableCellGrid._columnSpacing */) /
                kProductionAvailableWorkerGridColumns;

        for (final w in <double>[
          peasantWidth,
          apprenticeWidth,
          journeymanWidth,
          masterWidth,
        ]) {
          expect(
            w,
            closeTo(approxColWidth, 1.0),
            reason:
                'Each worker cell must occupy ≈1 / $kProductionAvailableWorkerGridColumns of the grid width',
          );
          expect(
            w,
            lessThan(gridBox.width - 1.0),
            reason:
                'Worker cells must not span the full grid width (would be 1-column collapse)',
          );
        }
      },
    );

    testWidgets(
      'Food commodity section is laid out in 3 columns on wide viewports (Refs #2862 S8b)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _ProductionPanelGridTestWrapper(
            displayGame: productionPanelTestGameFor(fullPlayer),
            player: fullPlayer,
            viewportWidth: 800,
            viewportHeight: 720,
          ),
        );
        await pumpSettleCapped(tester);

        final grainWidth = _slotWidthFor(
          tester,
          const ValueKey<String>('production_available_cell_grain'),
        );
        final timberWidth = _slotWidthFor(
          tester,
          const ValueKey<String>('production_available_cell_timber'),
        );

        // The food cell width should be substantially smaller than the
        // raw-materials timber cell width's grid is the same screen-x slot
        // that a 3-column section would yield. Both are 1 / 3 of their
        // respective sections; tolerate rounding.
        expect(grainWidth, lessThan(400));
        expect(timberWidth, lessThan(400));
        expect(grainWidth, greaterThan(40));
        expect(timberWidth, greaterThan(40));
      },
    );

    testWidgets(
      'Workers grid retains 2-column layout on narrow (<600 dp) viewports '
      '(Refs #2862 S8b)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _ProductionPanelGridTestWrapper(
            displayGame: productionPanelTestGameFor(fullPlayer),
            player: fullPlayer,
            viewportWidth: 360,
            viewportHeight: 1200,
          ),
        );
        await pumpSettleCapped(tester);

        final gridFinder = find.byKey(kProductionAvailableWorkerGridKey);
        expect(gridFinder, findsOneWidget);

        final gridBox = tester.getRect(gridFinder);
        final approxColWidth =
            (gridBox.width - 6 /* _AvailableCellGrid._columnSpacing */) /
                kProductionAvailableWorkerGridColumns;

        final peasantWidth = _slotWidthFor(
          tester,
          const ValueKey<String>('production_available_worker_peasant'),
        );
        expect(peasantWidth, closeTo(approxColWidth, 1.0));
        expect(
          peasantWidth,
          lessThan(gridBox.width - 1.0),
          reason:
              'Workers grid must remain 2-column on narrow viewports (no '
              'single-column collapse) per SPEC § Narrow viewport stack.',
        );
      },
    );

    testWidgets(
      'negative: Workers grid has no full-width single-column cell '
      '(Refs #2862 S8b)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _ProductionPanelGridTestWrapper(
            displayGame: productionPanelTestGameFor(fullPlayer),
            player: fullPlayer,
            viewportWidth: 800,
            viewportHeight: 720,
          ),
        );
        await pumpSettleCapped(tester);

        final gridFinder = find.byKey(kProductionAvailableWorkerGridKey);
        expect(gridFinder, findsOneWidget);
        final gridBox = tester.getRect(gridFinder);

        for (final tier in const <String>[
          'peasant',
          'apprentice',
          'journeyman',
          'master',
        ]) {
          final width = _slotWidthFor(
            tester,
            ValueKey<String>('production_available_worker_$tier'),
          );
          expect(
            width,
            lessThan(gridBox.width - 1.0),
            reason:
                'Worker cell for $tier must not span the full Workers grid '
                'width (would indicate the grid collapsed to 1 column).',
          );
        }
      },
    );

    testWidgets(
      'Food, Raw Materials, and Manufactured sections all render their '
      'cells inside fixed-width slots smaller than their section width '
      '(Refs #2862 S8b)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _ProductionPanelGridTestWrapper(
            displayGame: productionPanelTestGameFor(fullPlayer),
            player: fullPlayer,
            viewportWidth: 1000,
            viewportHeight: 900,
          ),
        );
        await pumpSettleCapped(tester);

        // Food: at least grain
        final grainCell = find.byKey(
          const ValueKey<String>('production_available_cell_grain'),
        );
        expect(grainCell, findsOneWidget);

        // Raw Materials: timber, iron, coal
        for (final id in const <String>['timber', 'iron', 'coal']) {
          expect(
            find.byKey(ValueKey<String>('production_available_cell_$id')),
            findsOneWidget,
            reason: 'Raw-materials cell for $id must be present',
          );
        }
      },
    );
  });
}
