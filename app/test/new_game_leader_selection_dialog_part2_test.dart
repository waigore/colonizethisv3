import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';

const Key _kSlotPickersStackedColumnKey = ValueKey<String>(
  'newGameLeaderDialogSlotPickersColumn',
);
const Key _kSlotPickersSideBySideRowKey = ValueKey<String>(
  'newGameLeaderDialogSlotPickersRow',
);

void main() {
  suppressLogsForTests();

  // Refs #2870 R3 / #3507 D2 — narrow slot-row stacking at
  // `< kLeaderSelectionNarrowBreakpoint` (540 dp), the DLG10001-dedicated
  // breakpoint matching the mockup `@media (min-width: 540px)` rule, per
  // SPEC/ui/new-game-leader-selection-dialog.md.
  // SPEC: `SPEC/ui/new-game-leader-selection-dialog.md` § Layout / wireframe
  // + § Acceptance Criteria narrow-viewport stacking AC; mirrors
  // `SPEC/ui/mobile-adaptation.md` § 4 Game Setup.
  group('NewGameLeaderSelectionDialog narrow slot stacking', () {
    Future<void> pumpDialogAt(
      WidgetTester tester, {
      required Size surfaceSize,
    }) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.colonial,
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    final base = GameSetupConfig.defaultConfig;
                    final naming = defaultNamingConfig;
                    final initial = <String, String>{};
                    for (final gpId in base.selectedGreatPowerIds) {
                      final gp = naming.gpById(gpId);
                      if (gp != null && gp.leaderVariants.isNotEmpty) {
                        initial[gpId] = gp.defaultLeaderVariantId;
                      }
                    }
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => NewGameLeaderSelectionDialog(
                        baseConfig: base,
                        naming: naming,
                        initialLeaderByGpId: initial,
                        blessedProfileNames: const [],
                        onCancel: () => Navigator.of(ctx).pop(),
                        onConfirmed: (_, _, _, _, _, _, _) {},
                      ),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('wide viewport (>= 540 dp): slot bodies render side-by-side row, '
        'no stacked column body, no exception', (WidgetTester tester) async {
      await pumpDialogAt(tester, surfaceSize: const Size(800, 1300));

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(_kSlotPickersSideBySideRowKey),
        findsNWidgets(6),
        reason:
            'Wide viewport must render one side-by-side row per slot '
            '(SPEC/ui/new-game-leader-selection-dialog.md narrow stacking AC).',
      );
      expect(
        find.byKey(_kSlotPickersStackedColumnKey),
        findsNothing,
        reason:
            'Wide viewport must not mount the stacked column body '
            '(negative AC).',
      );
      expect(
        find.byType(CtDropdown<String>),
        findsAtLeast(12),
        reason: 'Six slot rows × (nation + leader) = 12 dropdowns.',
      );
    });

    testWidgets('narrow viewport (< 540 dp): slot bodies render stacked column, '
        'no side-by-side row body, no exception', (WidgetTester tester) async {
      await pumpDialogAt(tester, surfaceSize: const Size(480, 1300));

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(_kSlotPickersStackedColumnKey),
        findsNWidgets(6),
        reason:
            'Narrow viewport must render one stacked column per slot '
            '(SPEC/ui/new-game-leader-selection-dialog.md narrow stacking AC).',
      );
      expect(
        find.byKey(_kSlotPickersSideBySideRowKey),
        findsNothing,
        reason:
            'Narrow viewport must not mount the side-by-side row body '
            '(negative AC).',
      );
      expect(
        find.byType(CtDropdown<String>),
        findsAtLeast(12),
        reason:
            'Both nation and leader dropdowns still mount in the stacked '
            'layout — six slots × two dropdowns = 12.',
      );
    });

    testWidgets('boundary: viewport exactly at 540 dp uses wide row body '
        '(breakpoint is strict <)', (WidgetTester tester) async {
      await pumpDialogAt(tester, surfaceSize: const Size(540, 1300));

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(_kSlotPickersSideBySideRowKey),
        findsNWidgets(6),
        reason:
            '540 dp is the boundary — kLeaderSelectionNarrowBreakpoint is a '
            'strict less-than check, so 540 dp keeps the wide row body.',
      );
      expect(find.byKey(_kSlotPickersStackedColumnKey), findsNothing);
    });
  });
}
