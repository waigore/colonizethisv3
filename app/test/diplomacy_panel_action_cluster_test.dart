// Widget tests for the wide-row action cluster on the Diplomacy panel,
// pinning SPEC/ui/diplomacy-panel.md § Action button styling (compact
// variant metrics + display-font label) and § Responsive layout (wide
// cluster bounded by available row width + left-to-right flow). Refs #3621.
//
// The fixture seeds a human Great Power `gp1` at peace with a second Great
// Power `gp2` so the row renders the full GP action matrix (multiple
// buttons), which is the case the issue targets for the trailing cluster.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
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
          diplomacyActionClusterPanelHost(viewportSize: const Size(800, 1200)),
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

    testWidgets('action buttons use the compact display-font label '
        '(Cinzel, kDiplomacyActionButtonFontSize)', (
      WidgetTester tester,
    ) async {
      await bindSurface(tester);
      await tester.pumpWidget(
        diplomacyActionClusterPanelHost(viewportSize: const Size(800, 1200)),
      );
      await _pumpBuilt(tester);

      final Finder declareWar = find.text('Declare War');
      expect(declareWar, findsOneWidget);
      final Text label = tester.widget<Text>(declareWar);
      expect(label.style?.fontFamily, editorialMonocleDisplayFontFamily);
      expect(label.style?.fontSize, kDiplomacyActionButtonFontSize);
    });

    testWidgets('action buttons use the compact CtNinePatchButton variant '
        '(24 dp min height, 7 x 3 dp padding, shrink-wrap)', (
      WidgetTester tester,
    ) async {
      await bindSurface(tester);
      await tester.pumpWidget(
        diplomacyActionClusterPanelHost(viewportSize: const Size(800, 1200)),
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
    });
  });
}
