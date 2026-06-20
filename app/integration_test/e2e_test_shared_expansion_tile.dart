/// ExpansionTile helpers lifted from `e2e_test_shared.dart` (Refs #2336
/// Bottleneck 6 / parent-file size, H10).
///
/// Keeps the [ExpansionTile] rotation-state inspector and the
/// "expand each collapsed tile once" loop in a single focused module so
/// the parent `e2e_test_shared.dart` stays comfortably under the
/// `dart_file_non_comment_line_size` repo-lint budget per
/// `SPEC/program/repo-lint.md`. Mirrors the extraction cadence already
/// used by `e2e_test_shared_region_tabs.dart` (#2857) and the dismissal
/// / panel-opener / fleet-reach NW-predicate companion files. The
/// lifted helpers are byte-equivalent — public names and signatures
/// unchanged, dartdoc preserved verbatim, all call sites continue to
/// import through the unchanged `e2e_test_shared.dart` /
/// `e2e_helpers.dart` barrels.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart' show e2ePumpUntilConditionOrIdle;

/// True when [tileElement] (an [ExpansionTile] element) hosts a
/// [RotationTransition] whose `turns.value` is past the expanded threshold.
///
/// Material's default [ExpansionTile] keeps the [Icons.expand_more] icon
/// mounted whether collapsed or expanded — only its [RotationTransition]
/// flips from `0.0` (collapsed) to `0.5` (expanded). The previous
/// `find.byIcon(Icons.expand_more).isEmpty` heuristic therefore never
/// detected expansion: the loop tapped the same tile up to 32 times,
/// burning the full 800 ms post-tap budget per outer iteration (~26 s
/// per call) without leaving the tile expanded. Reading the rotation
/// state directly is robust against future Material changes that swap the
/// icon for an `expand_less` variant — at 0.5 turns either icon counts as
/// expanded. Refs GitHub #2336 H10 / Bottleneck 6.
bool e2eExpansionTileIsExpanded(Element tileElement) {
  var expanded = false;
  void visit(Element e) {
    if (expanded) return;
    final w = e.widget;
    if (w is RotationTransition && w.turns.value > 0.4) {
      expanded = true;
      return;
    }
    e.visitChildren(visit);
  }

  tileElement.visitChildren(visit);
  return expanded;
}

/// Expands every currently collapsed [ExpansionTile] in the widget tree.
///
/// Reads each tile's [RotationTransition] state via
/// [e2eExpansionTileIsExpanded] so the helper:
/// 1. **Skips already-expanded tiles** (the previous icon-based check
///    misidentified all tiles as collapsed because [Icons.expand_more]
///    stays mounted under [RotationTransition]).
/// 2. **Taps exactly once per collapsed tile**, then polls until the
///    rotation crosses the expanded threshold (or the bounded budget
///    elapses) — no more 26 s no-op cycles per call.
/// 3. **Exits early** once no collapsed tile remains, mirroring the
///    documented "expand each once" contract.
///
/// Panel-rebuild safe: each outer iteration re-enumerates tiles after a
/// successful expand, so a list-view rebuild that shifts tile order does
/// not cause repeated taps on the same tile. Refs GitHub #2336.
Future<void> e2eExpandEachExpansionTileOnce(WidgetTester tester) async {
  for (var safety = 0; safety < 32; safety++) {
    final tiles = find.byType(ExpansionTile);
    final tileElements = tiles.evaluate().toList();
    if (tileElements.isEmpty) {
      return;
    }

    var expandedOne = false;
    for (var j = 0; j < tileElements.length; j++) {
      final tileElement = tileElements[j];
      if (e2eExpansionTileIsExpanded(tileElement)) {
        continue;
      }
      final tileAt = tiles.at(j);
      final expandIcon = find.descendant(
        of: tileAt,
        matching: find.byIcon(Icons.expand_more),
      );
      if (expandIcon.evaluate().isEmpty) {
        continue;
      }
      final iconHit = expandIcon.first;
      await tester.ensureVisible(iconHit);
      await e2ePumpUntilConditionOrIdle(
        tester,
        () => expandIcon.hitTestable().evaluate().isNotEmpty,
        timeout: const Duration(milliseconds: 400),
        phaseName: 'pump_until_expand_icon_tappable',
      );
      await tester.tap(iconHit, warnIfMissed: false);
      await e2ePumpUntilConditionOrIdle(
        tester,
        () {
          final elements = tileAt.evaluate();
          if (elements.isEmpty) return false;
          return e2eExpansionTileIsExpanded(elements.single);
        },
        timeout: const Duration(milliseconds: 800),
        phaseName: 'pump_until_expansion_tile_open',
      );
      expandedOne = true;
      break;
    }
    if (!expandedOne) {
      return;
    }
  }
}
