// Visual goldens for DLG10001 (`NewGameLeaderSelectionDialog`) per
// `SPEC/ui/new-game-leader-selection-dialog.md` § Acceptance Criteria
// (visual baseline) and the authoritative mockup
// `SPEC/ui/mockups/DLG10001-leader-selection-dialog.html` (Refs #3507).
//
// The structural / copy / breakpoint contracts are pinned by
// `new_game_leader_selection_dialog_test.dart` and
// `mobile_320dp_min_viewport_test.dart`; this file adds the
// `matchesGoldenFile` visual proof the issue requires at a wide
// (>= kLeaderSelectionNarrowBreakpoint, 540 dp — slot pickers side-by-side)
// and a narrow (320 dp minimum viewport — slot pickers stacked) layout.
//
// The dialog is rendered directly (not via `showDialog`) so a keyed
// `RepaintBoundary` can wrap the framed surface for a deterministic capture,
// using the running app's canonical `AppThemes.editorialMonocle` theme
// (`colonizethis-ui-design.mdc` dark-theme mandate), matching the production
// breakdown golden harness pattern.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';

import 'golden_capture_harness.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpDialogForGolden(
    WidgetTester tester, {
    required Size surfaceSize,
    required Key boundaryKey,
  }) async {
    final base = GameSetupConfig.defaultConfig;
    final naming = defaultNamingConfig;
    final initial = <String, String>{};
    for (final gpId in base.selectedGreatPowerIds) {
      final gp = naming.gpById(gpId);
      if (gp != null && gp.leaderVariants.isNotEmpty) {
        initial[gpId] = gp.defaultLeaderVariantId;
      }
    }

    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: surfaceSize,
      center: false,
      includeLocalizations: true,
      child: NewGameLeaderSelectionDialog(
        baseConfig: base,
        naming: naming,
        initialLeaderByGpId: initial,
        blessedProfileNames: const [],
        onCancel: () {},
        onConfirmed: (_, _, _, _, _, _, _) {},
      ),
    );
  }

  testWidgets(
    'golden: wide viewport (>= 540 dp) renders side-by-side slot pickers '
    '(Refs #3507)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'leaderSelectionDialogWideGolden',
      );
      // 600 dp width is >= kLeaderSelectionNarrowBreakpoint (540 dp), so the
      // slot pickers lay out side-by-side per the mockup
      // `@media (min-width: 540px)` rule.
      await pumpDialogForGolden(
        tester,
        surfaceSize: const Size(600, 900),
        boundaryKey: boundaryKey,
      );

      expect(tester.takeException(), isNull);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/new_game_leader_selection_dialog_wide.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: narrow viewport (320 dp) renders stacked slot pickers '
    '(Refs #3507)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'leaderSelectionDialogNarrowGolden',
      );
      // 320 dp width is < kLeaderSelectionNarrowBreakpoint (540 dp), so the
      // slot pickers stack vertically with no RenderFlex overflow at the
      // minimum supported viewport (per mobile-adaptation.md § 7).
      await pumpDialogForGolden(
        tester,
        surfaceSize: const Size(320, 900),
        boundaryKey: boundaryKey,
      );

      expect(tester.takeException(), isNull);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/new_game_leader_selection_dialog_narrow_320.png',
        ),
      );
    },
  );
}
