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

  testWidgets('Widgetbook registers Grant Aid Set Subsidy enabled', (
    tester,
  ) async {
    final useCase = findWidgetbookUseCase(
      provinceOverlayDirectories,
      folderName: 'Province Overlay',
      useCaseName: 'Standalone — Political Grant Aid Set Subsidy enabled',
    );
    await pumpWidgetbookUseCaseAtSize(
      tester,
      useCase,
      size: const Size(800, 640),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CtActionTextButton>(
            find.widgetWithText(
              CtActionTextButton,
              l10n.provinceOverlay_grantAidAction,
            ),
          )
          .enabled,
      isTrue,
    );
    expect(find.text(l10n.provinceOverlay_setSubsidyAction), findsOneWidget);
  });

  testWidgets('Widgetbook registers Grant Aid disabled', (tester) async {
    final useCase = findWidgetbookUseCase(
      provinceOverlayDirectories,
      folderName: 'Province Overlay',
      useCaseName: 'Standalone — Political Grant Aid disabled',
    );
    await pumpWidgetbookUseCaseAtSize(
      tester,
      useCase,
      size: const Size(800, 640),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CtActionTextButton>(
            find.widgetWithText(
              CtActionTextButton,
              l10n.provinceOverlay_grantAidAction,
            ),
          )
          .enabled,
      isFalse,
    );
  });

  testWidgets('Widgetbook registers Grant Aid pending and hidden', (
    tester,
  ) async {
    final pending = findWidgetbookUseCase(
      provinceOverlayDirectories,
      folderName: 'Province Overlay',
      useCaseName: 'Standalone — Political Grant Aid pending',
    );
    await pumpWidgetbookUseCaseAtSize(
      tester,
      pending,
      size: const Size(800, 640),
    );
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_cancelGrantAidAction,
      ),
      findsOneWidget,
    );
    final subsidyPending = findWidgetbookUseCase(
      provinceOverlayDirectories,
      folderName: 'Province Overlay',
      useCaseName: 'Standalone — Political Set Subsidy pending',
    );
    await pumpWidgetbookUseCaseAtSize(
      tester,
      subsidyPending,
      size: const Size(800, 640),
    );
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_cancelSetSubsidyAction,
      ),
      findsOneWidget,
    );
    final hidden = findWidgetbookUseCase(
      provinceOverlayDirectories,
      folderName: 'Province Overlay',
      useCaseName: 'Standalone — Political Grant Aid Set Subsidy hidden',
    );
    await pumpWidgetbookUseCaseAtSize(
      tester,
      hidden,
      size: const Size(800, 640),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.provinceOverlay_grantAidAction), findsNothing);
    expect(find.text(l10n.provinceOverlay_setSubsidyAction), findsNothing);
  });

  testWidgets('Widgetbook registers Grant Aid Set Subsidy 320 dp', (
    tester,
  ) async {
    final useCase = findWidgetbookUseCase(
      provinceOverlayDirectories,
      folderName: 'Province Overlay',
      useCaseName: 'Standalone — Political Grant Aid Set Subsidy 320 dp',
    );
    await pumpWidgetbookUseCaseAtSize(
      tester,
      useCase,
      size: const Size(320, 640),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<CtActionTextButton>(
            find.widgetWithText(
              CtActionTextButton,
              l10n.provinceOverlay_grantAidAction,
            ),
          )
          .enabled,
      isFalse,
    );
    expect(find.text(l10n.provinceOverlay_setSubsidyAction), findsOneWidget);
  });
}
