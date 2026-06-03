// Pins the dark editorial-monocle section-header Material-fallback
// regression guard for ProvinceSeaZoneDetailOverlay (S4 — sections layer).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Acceptance criteria — "Dark-theme section header — Material fallback
// regression guard" (Refs #2865).
//
// The existing `province_overlay_section_label_test.dart` slice already
// pins that every section header renders via `CtSectionLabel` (positive
// AC) and that no raw bold `Text` heading survives. This slice adds the
// complementary *negative* guard from the SPEC AC:
//
//   "the UI layer does not mount a Material `ListSubheader` widget for
//    that header and does not paint the underline using
//    `Theme.of(context).colorScheme.outline` (the `CtSectionLabel`-owned
//    `EditorialMonoclePalette.accentDim` underline is the single source)."
//
// Under `AppThemes.editorialMonocle` the dark theme wires
// `colorScheme.outline` to `EditorialMonoclePalette.border`, which is a
// distinct palette token from `EditorialMonoclePalette.accentDim` (the
// `CtSectionLabel` underline). The `isNot(colorScheme.outline)` assertion
// is therefore valid and non-tautological (unlike the `onSurface == fg`
// body-token cases that intentionally drop that guard).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';

Widget _darkProvinceOverlay() {
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
      ),
    ),
  );
}

/// The bottom-border colour painted by each [CtSectionLabel] underline.
/// `CtSectionLabel` builds `Padding > DecoratedBox > Padding > Text`, so a
/// single `DecoratedBox` descendant carries the underline `BorderSide`.
List<Color?> _sectionLabelUnderlineColors(WidgetTester tester) {
  final colors = <Color?>[];
  for (final labelElement in find.byType(CtSectionLabel).evaluate()) {
    final decoratedFinder = find.descendant(
      of: find.byWidget(labelElement.widget),
      matching: find.byType(DecoratedBox),
    );
    expect(
      decoratedFinder,
      findsOneWidget,
      reason: 'Each CtSectionLabel must paint exactly one DecoratedBox '
          'underline band.',
    );
    final decorated = tester.widget<DecoratedBox>(decoratedFinder);
    final decoration = decorated.decoration as BoxDecoration;
    colors.add(decoration.border?.bottom.color);
  }
  return colors;
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay section-header Material-fallback '
    'regression guard (SPEC § Dark-theme section header — Material '
    'fallback regression guard)',
    () {
      testWidgets(
        'no Material ListTile-style header is mounted for the section '
        'headers (negative guard against a Material list-subheader path)',
        (WidgetTester tester) async {
          await tester.pumpWidget(_darkProvinceOverlay());
          await tester.pumpAndSettle();

          // The canonical section headers must render via CtSectionLabel
          // only. A Material `ListTile` (the closest concrete proxy for the
          // "ListSubheader" the SPEC AC forbids) must never carry a section
          // header in the overlay subtree.
          expect(
            find.byType(ListTile),
            findsNothing,
            reason:
                'Section headers must render via CtSectionLabel, never a '
                'Material list-subheader/ListTile path (SPEC AC '
                '"Dark-theme section header — Material fallback regression '
                'guard").',
          );
        },
      );

      testWidgets(
        'every CtSectionLabel underline resolves to '
        'EditorialMonoclePalette.accentDim and never to '
        'Theme.colorScheme.outline under editorialMonocle',
        (WidgetTester tester) async {
          await tester.pumpWidget(_darkProvinceOverlay());
          await tester.pumpAndSettle();

          final outline = Theme.of(
            tester.element(find.byType(CtSectionLabel).first),
          ).colorScheme.outline;

          final underlineColors = _sectionLabelUnderlineColors(tester);
          expect(
            underlineColors,
            isNotEmpty,
            reason: 'The province overlay must render at least one '
                'CtSectionLabel underline.',
          );

          for (final color in underlineColors) {
            expect(
              color,
              isNotNull,
              reason:
                  'Each section underline must declare its own colour, not '
                  'fall through to a default border.',
            );
            expect(
              color,
              EditorialMonoclePalette.accentDim,
              reason:
                  'Each section underline must resolve to '
                  'EditorialMonoclePalette.accentDim (the CtSectionLabel '
                  'single source) per SPEC AC.',
            );
            expect(
              color,
              isNot(outline),
              reason:
                  'Each section underline must NOT be painted from '
                  'Theme.of(context).colorScheme.outline (wired to '
                  'EditorialMonoclePalette.border under editorialMonocle, a '
                  'distinct token from accentDim) per SPEC AC.',
            );
          }
        },
      );
    },
  );
}
