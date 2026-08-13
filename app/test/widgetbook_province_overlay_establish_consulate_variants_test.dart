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
  const prefix = 'Standalone — Political Establish Consulate';

  for (final suffix in ['enabled', 'disabled', 'pending', 'hidden']) {
    testWidgets('Widgetbook registers Establish Consulate $suffix', (
      tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        provinceOverlayDirectories,
        folderName: 'Province Overlay',
        useCaseName: '$prefix $suffix',
      );
      await pumpWidgetbookUseCaseAtSize(
        tester,
        useCase,
        size: const Size(800, 640),
      );
      await tester.pumpAndSettle();

      final establish = find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_establishConsulateAction,
      );
      final cancel = find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_cancelEstablishConsulateAction,
      );
      switch (suffix) {
        case 'enabled':
          expect(tester.widget<CtActionTextButton>(establish).enabled, isTrue);
        case 'disabled':
          expect(tester.widget<CtActionTextButton>(establish).enabled, isFalse);
        case 'pending':
          expect(cancel, findsOneWidget);
        case 'hidden':
          expect(establish, findsNothing);
          expect(cancel, findsNothing);
      }
    });
  }
}
