// Pins the enabled (clickable) half of Tile inline-action non-clickable contract.
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md § Tile inline actions.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_icon_action.dart';

import 'province_overlay_tile_inline_action_non_clickable_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'enabled inline actions are clickable: tapping invokes callbacks and '
    'actions are not wrapped in IgnorePointer',
    (WidgetTester tester) async {
      var exploreTapped = false;
      var prospectTapped = false;
      var buildTapped = false;
      await tester.pumpWidget(
        overlayWithInlineActions(
          showExploreActionIcon: true,
          exploreActionEnabled: true,
          onExploreWithExplorerTap: () => exploreTapped = true,
          showProspectActionIcon: true,
          prospectActionEnabled: true,
          onProspectWithExplorerTap: () => prospectTapped = true,
          showBuildImprovementActionIcon: true,
          buildImprovementActionEnabled: true,
          buildImprovementActionHasMatchingUnits: true,
          onBuildImprovementTap: () => buildTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      for (final tooltip in const <String>[
        'Explore with explorer',
        'Prospect with explorer',
      ]) {
        final finder = find.byTooltip(tooltip);
        expect(finder, findsOneWidget);
        expect(
          find.descendant(of: finder, matching: find.byType(IgnorePointer)),
          findsNothing,
        );
        final action = iconActionByTooltip(tester, tooltip);
        expect(action.enabled, isTrue);
        expect(action.onPressed, isNotNull);
      }

      final buildImprovementFinder = find.byWidgetPredicate(
        (widget) => widget is CtIconAction && widget.icon == Icons.handyman,
      );
      expect(buildImprovementFinder, findsOneWidget);
      expect(
        find.descendant(
          of: buildImprovementFinder,
          matching: find.byType(IgnorePointer),
        ),
        findsNothing,
      );
      final buildAction = buildImprovementIconAction(tester);
      expect(buildAction.enabled, isTrue);
      expect(buildAction.onPressed, isNotNull);

      await tester.tap(find.byTooltip('Explore with explorer'));
      await tester.tap(find.byTooltip('Prospect with explorer'));
      await tester.tap(buildImprovementFinder);
      await tester.pumpAndSettle();

      expect(exploreTapped, isTrue);
      expect(prospectTapped, isTrue);
      expect(buildTapped, isTrue);
    },
  );
}
