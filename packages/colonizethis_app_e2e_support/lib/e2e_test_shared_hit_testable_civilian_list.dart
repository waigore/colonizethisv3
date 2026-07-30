import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared_hit_testable_scroll.dart';

double _e2eScrollPositionPixels(WidgetTester tester, Finder scrollable) {
  final state = tester.state<ScrollableState>(scrollable.first);
  return state.position.pixels;
}

/// Scrolls the civilian-panel [ListView] through its full extent (bottom then
/// top) so every unit row is built before [e2eCollectTextPreorder] walks the
/// tree.
///
/// Why this exists (Refs GitHub #2336 AC6 / AC7 / AC10): the bottom-sheet
/// panel caps list height (~308 dp visible) while the E2E roster can list more
/// units than fit on screen. `ListView` virtualization omits off-screen row
/// `Text` nodes, so a preorder snapshot taken at scroll offset `0` can be
/// shorter than [civilianUnitsPanelExpectedTexts] (for example the second
/// idle `Explorer` row at indices 25–29). Driving the list to max extent and
/// back — together with the E2E `cacheExtent` on [UnitsPanelShell] — keeps
/// every row mounted for the assertion pass.
Future<void> e2ePrepareCivilianPanelListForTextCollection(
  WidgetTester tester,
) async {
  final root = find.byKey(kCtE2ECivilianPanelRootKey);
  if (root.evaluate().isEmpty) {
    return;
  }
  final scrollable = find.descendant(
    of: root,
    matching: find.byType(Scrollable),
  );
  if (scrollable.evaluate().isEmpty) {
    return;
  }
  await e2eWaitScrollableOnScreen(tester, scrollable);
  const maxSteps = 25;
  for (var i = 0; i < maxSteps; i++) {
    final before = _e2eScrollPositionPixels(tester, scrollable);
    final dragged = await e2eDragScrollableFromVisiblePoint(
      tester,
      scrollable,
      const Offset(0, -200),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final after = _e2eScrollPositionPixels(tester, scrollable);
    if (!dragged || (after - before).abs() < 0.5) {
      break;
    }
  }
  for (var i = 0; i < maxSteps; i++) {
    final before = _e2eScrollPositionPixels(tester, scrollable);
    if (before < 0.5) {
      break;
    }
    await e2eDragScrollableFromVisiblePoint(
      tester,
      scrollable,
      const Offset(0, 200),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final after = _e2eScrollPositionPixels(tester, scrollable);
    if ((after - before).abs() < 0.5) {
      break;
    }
  }
}
