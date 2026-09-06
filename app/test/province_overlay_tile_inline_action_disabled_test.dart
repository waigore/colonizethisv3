// Disabled Tile inline-action non-clickable pins (SPEC § L388/L392/L401).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_icon_action.dart';

import 'province_overlay_tile_inline_action_non_clickable_support.dart';

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay Tile inline actions — disabled', () {
    testWidgets(
      'disabled Explore inline action is non-clickable (zero-Explorer AC L392)',
      (WidgetTester tester) async {
        var tapped = false;
        await tester.pumpWidget(
          overlayWithInlineActions(
            showExploreActionIcon: true,
            exploreActionEnabled: false,
            onExploreWithExplorerTap: () => tapped = true,
          ),
        );
        await tester.pumpAndSettle();

        final tooltip = find.byTooltip('Explore with explorer');
        expect(tooltip, findsOneWidget);
        expect(
          find.descendant(of: tooltip, matching: find.byType(IgnorePointer)),
          findsOneWidget,
        );

        final action = iconActionByTooltip(tester, 'Explore with explorer');
        expect(action.enabled, isFalse);
        expect(action.onPressed, isNull);

        await tester.tap(tooltip, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(tapped, isFalse);
      },
    );

    testWidgets(
      'disabled Prospect inline action is non-clickable (zero-Explorer AC L388)',
      (WidgetTester tester) async {
        var tapped = false;
        await tester.pumpWidget(
          overlayWithInlineActions(
            showProspectActionIcon: true,
            prospectActionEnabled: false,
            onProspectWithExplorerTap: () => tapped = true,
          ),
        );
        await tester.pumpAndSettle();

        final tooltip = find.byTooltip('Prospect with explorer');
        expect(tooltip, findsOneWidget);
        expect(
          find.descendant(of: tooltip, matching: find.byType(IgnorePointer)),
          findsOneWidget,
        );

        final action = iconActionByTooltip(tester, 'Prospect with explorer');
        expect(action.enabled, isFalse);
        expect(action.onPressed, isNull);

        await tester.tap(tooltip, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(tapped, isFalse);
      },
    );

    testWidgets(
      'disabled Build improvement inline action is non-clickable (AC L401)',
      (WidgetTester tester) async {
        var tapped = false;
        await tester.pumpWidget(
          overlayWithInlineActions(
            showBuildImprovementActionIcon: true,
            buildImprovementActionEnabled: false,
            onBuildImprovementTap: () => tapped = true,
          ),
        );
        await tester.pumpAndSettle();

        final tooltip = find.byWidgetPredicate(
          (widget) => widget is CtIconAction && widget.icon == Icons.handyman,
        );
        expect(tooltip, findsOneWidget);
        expect(
          find.descendant(of: tooltip, matching: find.byType(IgnorePointer)),
          findsOneWidget,
        );

        final action = buildImprovementIconAction(tester);
        expect(action.enabled, isFalse);
        expect(action.onPressed, isNull);

        await tester.tap(tooltip, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(tapped, isFalse);
      },
    );
  });
}
