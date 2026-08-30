// Widget goldens for GAME20001 Labour Disband confirm (Refs #4601).
// Pins CtConfirmDialog Effect/Cost/When copy under AppThemes.editorialMonocle
// at default and 320 dp widths. SPEC/ui/production-panel.md § Disband (immediate).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_labour_disband_confirm.dart';
import 'package:colonizethis_app/widgets/ct_confirm_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'widget_test_assets.dart';

Widget _journeymanDisbandConfirm() {
  return Builder(
    builder: (context) {
      final l10n = appL10n(context);
      final name = labourDisbandConfirmTierName(l10n, WorkerTier.journeyman);
      return CtConfirmDialog(
        title: l10n.production_labourDisbandConfirmTitle(name),
        message: l10n.production_labourDisbandConfirmBody(name),
        confirmLabel: l10n.production_labourDisband,
        cancelLabel: l10n.common_cancel,
      );
    },
  );
}

Future<void> _pumpDisbandConfirmGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size physicalSize,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    settle: false,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: _journeymanDisbandConfirm(),
  );
}

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets('golden: Journeyman Disband confirm copy (AC 4, Refs #4601)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'production_labour_disband_confirm_golden',
    );
    await _pumpDisbandConfirmGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(540, 360),
    );

    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(find.byType(CtDialogShell), findsOneWidget);
    expect(find.byType(CtNinePatchButton), findsNWidgets(2));
    expect(find.textContaining('WorkerTier'), findsNothing);
    expect(find.textContaining('Peasant'), findsWidgets);
    expect(find.textContaining('Gold'), findsWidgets);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/production_labour_disband_confirm.png'),
    );
  });

  testWidgets('golden: Journeyman Disband confirm @ 320dp (AC 8, Refs #4601)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'production_labour_disband_confirm_320dp_golden',
    );
    await _pumpDisbandConfirmGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(kMinViewportWidth, 420),
    );

    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(find.byType(CtConfirmDialog), findsOneWidget);
    expect(find.textContaining('Cancel'), findsOneWidget);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/production_labour_disband_confirm_320dp.png'),
    );
  });
}
