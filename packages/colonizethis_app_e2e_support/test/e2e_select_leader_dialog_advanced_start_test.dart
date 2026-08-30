import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_bootstrap.dart';
import 'support/e2e_widget_pump_harness.dart';

/// Pins DLG10001 advanced-start selection at the CI desktop viewport (1280×720)
/// where the dropdown sits below the fold until the shell scrolls (Refs #3895).
void main() {
  suppressLogsForTests();

  Future<void> pumpLockedFullInitDialog(WidgetTester tester) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      wrapE2eApp(
        Scaffold(
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
        theme: AppThemes.colonial,
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'e2eSelectLeaderDialogAdvancedStart scrolls dropdown into view at 1280x720',
    (WidgetTester tester) async {
      await pumpLockedFullInitDialog(tester);

      await e2eSelectLeaderDialogAdvancedStart(tester, '50 Turns In (1598)');

      expect(
        find.widgetWithText(
          CtDropdown<AdvancedStartType>,
          '50 Turns In (1598)',
        ),
        findsOneWidget,
      );
    },
  );
}
