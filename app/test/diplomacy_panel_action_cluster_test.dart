// Widget tests for the wide-row action cluster on the Diplomacy panel,
// pinning SPEC/ui/diplomacy-panel.md § Action button styling (compact
// variant metrics + display-font label) and § Responsive layout (wide
// cluster bounded by available row width + left-to-right flow). Refs #3621.
//
// The fixture seeds a human Great Power `gp1` at peace with a second Great
// Power `gp2` so the row renders the full GP action matrix (multiple
// buttons), which is the case the issue targets for the trailing cluster.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'support/app_shell_harness.dart';

const MapTopology _emptyTopology = MapTopology(nodes: [], edges: []);

/// Human GP `gp1` holds an at-peace relation with GP `gp2`, so the GP row
/// renders the full overture + action matrix (several action buttons).
Game _greatPowerRowGame() {
  const ow = 'oldWorld';
  final home = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'Home',
    ownerId: 'gp1',
  );
  final rival = Province(
    id: '$ow|p2',
    regionId: ow,
    displayName: 'Rival',
    ownerId: 'gp2',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 4),
    oldWorld: RegionData(provinces: [home, rival], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  return Game(
    id: 'diplo-action-cluster',
    worldState: world,
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2'),
    ],
  );
}

Widget _panelHost({required Size viewportSize}) {
  return buildAppShell(
    viewport: viewportSize,
    child: Scaffold(
      body: DiplomacyPanel(
        game: _greatPowerRowGame(),
        humanPlayerId: 'gp1',
        topology: _emptyTopology,
        currentOrders: const Orders(),
        bus: AppEventBus.create(),
      ),
    ),
  );
}

Future<void> _pumpBuilt(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

/// Groups the rendered action-button rects into runs keyed by a quantized
/// top y-offset (within [tol] dp). Each run's lefts are returned sorted.
Map<double, List<Rect>> _runsByTop(List<Rect> rects, {double tol = 0.5}) {
  double quantize(double v) => (v / tol).roundToDouble() * tol;
  final Map<double, List<Rect>> byTop = <double, List<Rect>>{};
  for (final Rect r in rects) {
    byTop.putIfAbsent(quantize(r.top), () => <Rect>[]).add(r);
  }
  for (final List<Rect> run in byTop.values) {
    run.sort((Rect a, Rect b) => a.left.compareTo(b.left));
  }
  return byTop;
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
    return <Rect>[for (int i = 0; i < count; i++) tester.getRect(buttons.at(i))];
  }

  group('Diplomacy wide action cluster (Refs #3621)', () {
    test('cluster constants pin the compact contract', () {
      expect(kDiplomacyActionWrapSpacing, 4.0);
      expect(kDiplomacyActionButtonMinHeight, 24.0);
      expect(kDiplomacyActionButtonFontSize, 10.0);
    });

    testWidgets(
      'wide (> 500 dp): info is Expanded, trailing cluster is a Flexible '
      'Align(topRight) wrapping an end-aligned Wrap with no fixed-width cap',
      (WidgetTester tester) async {
        await bindSurface(tester);
        await tester.pumpWidget(
          _panelHost(viewportSize: const Size(800, 1200)),
        );
        await _pumpBuilt(tester);

        final Key bodyKey = ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2');
        expect(find.byKey(bodyKey), findsOneWidget);
        expect(tester.widget(find.byKey(bodyKey)), isA<Row>());

        // The info column sits in an Expanded sibling of the action cluster.
        expect(
          find.descendant(
            of: find.byKey(bodyKey),
            matching: find.byType(Expanded),
          ),
          findsOneWidget,
        );

        // The action Wrap is end-aligned with the normative 4 dp gaps.
        final Finder endWrap = find.descendant(
          of: find.byKey(bodyKey),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is Wrap &&
                w.alignment == WrapAlignment.end &&
                w.spacing == kDiplomacyActionWrapSpacing &&
                w.runSpacing == kDiplomacyActionWrapSpacing,
          ),
        );
        expect(endWrap, findsOneWidget);

        // The cluster is anchored to the trailing edge via Align(topRight)
        // wrapping that Wrap.
        final Finder topRightAlign = find.descendant(
          of: find.byKey(bodyKey),
          matching: find.byWidgetPredicate(
            (Widget w) => w is Align && w.alignment == Alignment.topRight,
          ),
        );
        expect(topRightAlign, findsOneWidget);
        expect(
          find.descendant(of: topRightAlign, matching: endWrap),
          findsOneWidget,
        );

        // Negative guard: no ConstrainedBox imposes a fixed finite maxWidth
        // on the trailing cluster (the former 180 dp cap is removed).
        final Finder cappedBox = find.descendant(
          of: topRightAlign,
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is ConstrainedBox && w.constraints.maxWidth.isFinite,
          ),
        );
        expect(
          cappedBox,
          findsNothing,
          reason:
              'Wide cluster must be bounded only by the available row width '
              '(no fixed-width ConstrainedBox) per SPEC § Responsive layout '
              '(Refs #3621).',
        );
      },
    );

    testWidgets(
      'action buttons use the compact display-font label '
      '(Cinzel, kDiplomacyActionButtonFontSize)',
      (WidgetTester tester) async {
        await bindSurface(tester);
        await tester.pumpWidget(
          _panelHost(viewportSize: const Size(800, 1200)),
        );
        await _pumpBuilt(tester);

        final Finder declareWar = find.text('Declare War');
        expect(declareWar, findsOneWidget);
        final Text label = tester.widget<Text>(declareWar);
        expect(label.style?.fontFamily, editorialMonocleDisplayFontFamily);
        expect(label.style?.fontSize, kDiplomacyActionButtonFontSize);
      },
    );

    testWidgets(
      'action buttons use the compact CtNinePatchButton variant '
      '(24 dp min height, 7 x 3 dp padding, shrink-wrap)',
      (WidgetTester tester) async {
        await bindSurface(tester);
        await tester.pumpWidget(
          _panelHost(viewportSize: const Size(800, 1200)),
        );
        await _pumpBuilt(tester);

        final Finder compactButtons = find.byWidgetPredicate(
          (Widget w) =>
              w is CtNinePatchButton &&
              w.minHeight == kDiplomacyActionButtonMinHeight &&
              w.padding == kDiplomacyActionButtonPadding &&
              w.shrinkWrap,
        );
        expect(compactButtons, findsWidgets);

        // Negative guard: no diplomacy action button retains the default
        // 48 dp panel-button min height.
        final Finder defaultHeightButtons = find.byWidgetPredicate(
          (Widget w) => w is CtNinePatchButton && w.minHeight == 48,
        );
        expect(defaultHeightButtons, findsNothing);
      },
    );

    testWidgets(
      'wide but width-constrained: cluster fills runs left-to-right and '
      'wraps without forming a vertical column',
      (WidgetTester tester) async {
        // 600 dp > kDiplomacyRowNarrowMaxWidth (wide variant) but narrow
        // enough that the full GP matrix cannot fit on one run.
        await bindSurface(tester, size: const Size(600, 1600));
        await tester.pumpWidget(
          _panelHost(viewportSize: const Size(600, 1200)),
        );
        await _pumpBuilt(tester);

        final Key bodyKey = ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2');
        final List<Rect> rects = actionRects(tester, bodyKey);
        expect(rects.length, greaterThanOrEqualTo(4));

        final Map<double, List<Rect>> runs = _runsByTop(rects);

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
        final Set<double> allLefts =
            rects.map((Rect r) => (r.left * 2).roundToDouble() / 2).toSet();
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
          _panelHost(viewportSize: const Size(4000, 1200)),
        );
        await _pumpBuilt(tester);

        final Key bodyKey = ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2');
        final List<Rect> rects = actionRects(tester, bodyKey);
        expect(rects.length, greaterThanOrEqualTo(4));

        final Map<double, List<Rect>> runs = _runsByTop(rects);
        expect(
          runs.length,
          1,
          reason:
              'Given ample width, all action buttons must share a single '
              'horizontal run (the cluster extends horizontally, not stacked).',
        );
      },
    );

    testWidgets(
      'narrow (<= 500 dp): action Wrap is start-aligned (no regression to '
      'wide flow)',
      (WidgetTester tester) async {
        await bindSurface(tester);
        await tester.pumpWidget(
          _panelHost(viewportSize: const Size(480, 1200)),
        );
        await _pumpBuilt(tester);

        final Key bodyKey = ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2');
        expect(tester.widget(find.byKey(bodyKey)), isA<Column>());

        final Finder startWrap = find.descendant(
          of: find.byKey(bodyKey),
          matching: find.byWidgetPredicate(
            (Widget w) => w is Wrap && w.alignment == WrapAlignment.start,
          ),
        );
        expect(startWrap, findsOneWidget);
      },
    );
  });
}
