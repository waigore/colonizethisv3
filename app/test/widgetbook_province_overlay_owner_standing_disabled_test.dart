// Pins Widgetbook MAP20001 Offer Peace disabled story (Refs #4479).
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  testWidgets(
    'Widgetbook registers Offer Peace disabled with validator reason',
    (tester) async {
      final useCase = findWidgetbookUseCase(
        provinceOverlayDirectories,
        folderName: 'Province Overlay',
        useCaseName:
            'Standalone — Political owner standing at war Offer Peace disabled',
      );
      await pumpWidgetbookUseCaseAtSize(
        tester,
        useCase,
        size: const Size(800, 640),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<CtActionTextButton>(
        find.widgetWithText(
          CtActionTextButton,
          l10n.provinceOverlay_offerPeaceAction,
        ),
      );
      expect(button.enabled, isFalse);
      expect(
        button.tooltip,
        'Already have a diplomatic order for this faction this turn',
      );
    },
  );
}
