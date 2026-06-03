// Pins the "non-clickable" half of the disabled inline-action contract for
// the ProvinceSeaZoneDetailOverlay Tile section.
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Province overlay content — Tile section inline actions:
//   - L388 "If the human player has zero Explorer units ... Prospect ...
//           disabled, grayscale, and non-clickable."
//   - L392 "... Explore with explorer visible but disabled, grayscale, and
//           non-clickable."
//   - L401 "... no Builder can validly assign build_improvement ... keeps the
//           icon visible but disabled, grayscale, and non-clickable."
//
// The dark-token tests in province_overlay_tile_section_dark_tokens_test.dart
// already pin the *grayscale* (disabled colour) half of these ACs. They do
// NOT pin the *non-clickable* half: that a disabled inline action ignores
// pointer input (its tap callback is never invoked, it is wrapped in an
// `IgnorePointer`, and it reports `Semantics(enabled: false)`). This file
// pins that behaviour with positive (enabled → clickable) and negative
// (disabled → non-clickable) cases for all three inline actions.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';

/// Builds the overlay with the Tile section inline actions shown and a
/// configurable enabled state plus tap-recording callbacks.
Widget _overlayWithInlineActions({
  bool showExploreActionIcon = false,
  bool exploreActionEnabled = false,
  VoidCallback? onExploreWithExplorerTap,
  bool showProspectActionIcon = false,
  bool prospectActionEnabled = false,
  VoidCallback? onProspectWithExplorerTap,
  bool showBuildImprovementActionIcon = false,
  bool buildImprovementActionEnabled = false,
  VoidCallback? onBuildImprovementTap,
}) {
  final game = demoGameForOverlay;
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: demoRegionForOverlay,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        humanPlayerId: game.players.first.id,
        playerView: demoHumanPlayerViewForOverlay,
        showExploreActionIcon: showExploreActionIcon,
        exploreActionEnabled: exploreActionEnabled,
        onExploreWithExplorerTap: onExploreWithExplorerTap,
        showProspectActionIcon: showProspectActionIcon,
        prospectActionEnabled: prospectActionEnabled,
        onProspectWithExplorerTap: onProspectWithExplorerTap,
        showBuildImprovementActionIcon: showBuildImprovementActionIcon,
        buildImprovementActionEnabled: buildImprovementActionEnabled,
        onBuildImprovementTap: onBuildImprovementTap,
      ),
    ),
  );
}

CtIconAction _iconActionByTooltip(WidgetTester tester, String tooltip) {
  // `CtIconAction` wraps itself in the `Tooltip` (Tooltip is its child), so it
  // is an ancestor of the tooltip rather than a descendant. Match the
  // `CtIconAction` directly by its `tooltip` property.
  return tester.widget<CtIconAction>(
    find.byWidgetPredicate(
      (widget) => widget is CtIconAction && widget.tooltip == tooltip,
    ),
  );
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay Tile inline actions — non-clickable when '
    'disabled (SPEC § Tile inline actions, ACs L388/L392/L401)',
    () {
      testWidgets(
        'disabled Explore inline action is non-clickable: tapping does not '
        'invoke the callback and the action is wrapped in IgnorePointer '
        '(zero-Explorer AC L392)',
        (WidgetTester tester) async {
          var tapped = false;
          await tester.pumpWidget(
            _overlayWithInlineActions(
              showExploreActionIcon: true,
              exploreActionEnabled: false,
              onExploreWithExplorerTap: () => tapped = true,
            ),
          );
          await tester.pumpAndSettle();

          final tooltip = find.byTooltip('Explore with explorer');
          expect(tooltip, findsOneWidget);

          // Non-clickable: the disabled action ignores pointer input.
          expect(
            find.descendant(of: tooltip, matching: find.byType(IgnorePointer)),
            findsOneWidget,
            reason:
                'A disabled Explore inline action must be wrapped in an '
                'IgnorePointer so it cannot receive taps (SPEC AC: zero '
                'Explorer units → Explore icon disabled and non-clickable).',
          );

          final action = _iconActionByTooltip(tester, 'Explore with explorer');
          expect(action.enabled, isFalse);
          expect(
            action.onPressed,
            isNull,
            reason:
                'The overlay must wire a disabled inline action to a null '
                'onPressed so no tap handler runs.',
          );

          await tester.tap(tooltip, warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(
            tapped,
            isFalse,
            reason:
                'Tapping a disabled Explore inline action must not invoke the '
                'explorer-shortcut callback (non-clickable contract).',
          );
        },
      );

      testWidgets(
        'disabled Prospect inline action is non-clickable: tapping does not '
        'invoke the callback and the action is wrapped in IgnorePointer '
        '(zero-Explorer AC L388)',
        (WidgetTester tester) async {
          var tapped = false;
          await tester.pumpWidget(
            _overlayWithInlineActions(
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

          final action = _iconActionByTooltip(tester, 'Prospect with explorer');
          expect(action.enabled, isFalse);
          expect(action.onPressed, isNull);

          await tester.tap(tooltip, warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(
            tapped,
            isFalse,
            reason:
                'Tapping a disabled Prospect inline action must not invoke the '
                'explorer-shortcut callback (non-clickable contract).',
          );
        },
      );

      testWidgets(
        'disabled Build improvement inline action is non-clickable: tapping '
        'does not invoke the callback and the action is wrapped in '
        'IgnorePointer (no-valid-Builder AC L401)',
        (WidgetTester tester) async {
          var tapped = false;
          await tester.pumpWidget(
            _overlayWithInlineActions(
              showBuildImprovementActionIcon: true,
              buildImprovementActionEnabled: false,
              onBuildImprovementTap: () => tapped = true,
            ),
          );
          await tester.pumpAndSettle();

          final tooltip = find.byTooltip('Build improvement');
          expect(tooltip, findsOneWidget);
          expect(
            find.descendant(of: tooltip, matching: find.byType(IgnorePointer)),
            findsOneWidget,
          );

          final action = _iconActionByTooltip(tester, 'Build improvement');
          expect(action.enabled, isFalse);
          expect(action.onPressed, isNull);

          await tester.tap(tooltip, warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(
            tapped,
            isFalse,
            reason:
                'Tapping a disabled Build improvement inline action must not '
                'invoke the build-improvement callback (non-clickable '
                'contract).',
          );
        },
      );

      testWidgets(
        'positive — enabled inline actions are clickable: tapping invokes the '
        'callback and the action is not wrapped in IgnorePointer',
        (WidgetTester tester) async {
          var exploreTapped = false;
          var prospectTapped = false;
          var buildTapped = false;
          await tester.pumpWidget(
            _overlayWithInlineActions(
              showExploreActionIcon: true,
              exploreActionEnabled: true,
              onExploreWithExplorerTap: () => exploreTapped = true,
              showProspectActionIcon: true,
              prospectActionEnabled: true,
              onProspectWithExplorerTap: () => prospectTapped = true,
              showBuildImprovementActionIcon: true,
              buildImprovementActionEnabled: true,
              onBuildImprovementTap: () => buildTapped = true,
            ),
          );
          await tester.pumpAndSettle();

          for (final tooltip in const <String>[
            'Explore with explorer',
            'Prospect with explorer',
            'Build improvement',
          ]) {
            final finder = find.byTooltip(tooltip);
            expect(finder, findsOneWidget);
            expect(
              find.descendant(of: finder, matching: find.byType(IgnorePointer)),
              findsNothing,
              reason:
                  'An enabled "$tooltip" inline action must remain interactive '
                  '(no IgnorePointer wrapper).',
            );
            final action = _iconActionByTooltip(tester, tooltip);
            expect(action.enabled, isTrue);
            expect(action.onPressed, isNotNull);
          }

          await tester.tap(find.byTooltip('Explore with explorer'));
          await tester.tap(find.byTooltip('Prospect with explorer'));
          await tester.tap(find.byTooltip('Build improvement'));
          await tester.pumpAndSettle();

          expect(exploreTapped, isTrue);
          expect(prospectTapped, isTrue);
          expect(
            buildTapped,
            isTrue,
            reason:
                'Tapping enabled inline actions must invoke their callbacks '
                '(clickable counterpart to the disabled non-clickable ACs).',
          );
        },
      );
    },
  );
}
