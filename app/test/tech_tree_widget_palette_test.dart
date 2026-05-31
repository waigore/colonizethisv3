// Regression test for #2914 S3: tech-tree node and edge chrome must
// resolve through `EditorialMonoclePalette` tokens rather than the
// pre-#2858 `Colors.grey.shade*` legacy fallbacks.
//
// SPEC: `SPEC/ui/tech-tree-widget.md` § Node states ("Locked: Greyed
// out or dimmed") and `SPEC/ui/pixel-art-ui-catalog.md` § Editorial
// monocle palette (single-source palette tokens).

import 'package:colonizethis_data/colonizethis_data.dart'
    show kTechIdWindSawMill, techCatalog;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/tech_tree_widget.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player player;

  setUpAll(() {
    final result = getDebugInitGameResult();
    game = result.game;
    player = game.players.first;
  });

  // Tech tree nodes render inside a `Container` with
  // `BorderRadius.circular(6)`. The legend's state samples also render
  // _TechNode widgets, so we pick the first node from the scrollable
  // tree area (not the legend wrap) by anchoring on a node's display
  // text and walking up to the nearest decorated container.
  Finder nodeContainerForText(String techDisplayName) {
    return find.ancestor(
      of: find.text(techDisplayName).first,
      matching: find.byWidgetPredicate((widget) {
        if (widget is! Container) return false;
        final decoration = widget.decoration;
        if (decoration is! BoxDecoration) return false;
        final radius = decoration.borderRadius;
        return radius is BorderRadius &&
            radius.topLeft == const Radius.circular(6);
      }),
    );
  }

  testWidgets(
    'locked tech node uses EditorialMonoclePalette.surface fill + '
    'border (#2914 S3 — no Colors.grey.shade* fallback)',
    (WidgetTester tester) async {
      final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechTreeWidget(game: game, player: emptyPlayer),
          ),
        ),
      );
      await tester.pumpAndSettle();

      const lockedTechName = 'Wind Saw Mill';
      expect(
        techCatalog.values.any((t) => t.id == kTechIdWindSawMill),
        isTrue,
        reason: 'Fixture: $lockedTechName must exist in techCatalog so '
            'the locked-state assertion has a target.',
      );
      final containers = nodeContainerForText(lockedTechName);
      expect(containers, findsWidgets);

      final container = tester.widgetList<Container>(containers).first;
      final decoration = container.decoration! as BoxDecoration;
      expect(
        decoration.color,
        equals(EditorialMonoclePalette.surface),
        reason: 'Locked tech node fill must resolve through '
            'EditorialMonoclePalette.surface (was Colors.grey.shade200).',
      );
      final border = decoration.border! as Border;
      expect(
        border.top.color,
        equals(EditorialMonoclePalette.border),
        reason: 'Locked tech node border must resolve through '
            'EditorialMonoclePalette.border (was Colors.grey.shade400).',
      );
    },
  );

  testWidgets(
    'tech tree edge painter is mounted alongside the dark-palette '
    'nodes (#2914 S3 — painter chrome resolves through palette tokens)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechTreeWidget(game: game, player: player),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pin that the tech tree still mounts a `_TechTreeEdgePainter`
      // under a `CustomPaint`; the painter's stroke colour is read
      // from `EditorialMonoclePalette.border` (refactored from
      // `Colors.grey.shade600`). The source-level grep in #2914 G1
      // covers the literal-color regression; here we only pin the
      // structural presence so the file is exercised in CI.
      final customPaints = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter.runtimeType.toString() == '_TechTreeEdgePainter',
      );
      expect(
        customPaints,
        findsWidgets,
        reason: 'TechTreeWidget should host at least one CustomPaint '
            'with the edge painter so the palette migration is exercised '
            'whenever the tree mounts.',
      );

      // Sanity: the palette token must not collapse to the legacy
      // `Colors.grey.shade600` value, otherwise the refactor would be
      // a no-op and the regression bar would be vacuous.
      expect(
        EditorialMonoclePalette.border,
        isNot(equals(Colors.grey.shade600)),
        reason: 'EditorialMonoclePalette.border must be visually distinct '
            'from the legacy Colors.grey.shade600 so the migration is '
            'observable in the rendered tree.',
      );
    },
  );
}
