// Pins MAP20001 Political Establish Embassy widget copy (Refs #4739).

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_establish_embassy_shortcut_fixtures.dart';
import 'province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();

  group('Political Establish Embassy widget', () {
    testWidgets('renders Establish Embassy under Owner when shown', (
      tester,
    ) async {
      final l10n = AppLocalizationsEn();
      final game = buildEstablishEmbassyShortcutGame(
        ownerId: kEstablishEmbassyMinorId,
      );
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: kEstablishEmbassyProvinceId,
          selectedTileKey: kEstablishEmbassyTileKey,
          showEstablishEmbassyControl: true,
          establishEmbassyEnabled: true,
          onEstablishEmbassyTap: () {},
        ),
      );
      expect(
        find.text(l10n.provinceOverlay_establishEmbassyAction),
        findsOneWidget,
      );
      expect(
        find.text(l10n.provinceOverlay_establishConsulateAction),
        findsNothing,
      );
    });

    testWidgets('pending shows Cancel label', (tester) async {
      final l10n = AppLocalizationsEn();
      final game = buildEstablishEmbassyShortcutGame(
        ownerId: kEstablishEmbassyMinorId,
      );
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: kEstablishEmbassyProvinceId,
          selectedTileKey: kEstablishEmbassyTileKey,
          showEstablishEmbassyControl: true,
          establishEmbassyEnabled: true,
          establishEmbassyPending: true,
          onEstablishEmbassyTap: () {},
        ),
      );
      expect(
        find.text(l10n.provinceOverlay_cancelEstablishEmbassyAction),
        findsOneWidget,
      );
    });

    testWidgets('hidden when control flag false', (tester) async {
      final l10n = AppLocalizationsEn();
      final game = buildEstablishEmbassyShortcutGame(
        ownerId: kEstablishEmbassyHumanPlayerId,
        asMinor: false,
      );
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: kEstablishEmbassyProvinceId,
          selectedTileKey: kEstablishEmbassyTileKey,
        ),
      );
      expect(
        find.text(l10n.provinceOverlay_establishEmbassyAction),
        findsNothing,
      );
    });

    testWidgets('narrow disabled shows inline rejection reason', (
      tester,
    ) async {
      final game = buildEstablishEmbassyShortcutGame(
        ownerId: kEstablishEmbassyMinorId,
      );
      const reason = 'Need Diplomatic Expertise';
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: buildProvinceOverlayDarkThemeShell(
            game: game,
            displayId: kEstablishEmbassyProvinceId,
            selectedTileKey: kEstablishEmbassyTileKey,
            showEstablishEmbassyControl: true,
            establishEmbassyEnabled: false,
            establishEmbassyRejectionReason: reason,
          ),
        ),
      );
      expect(find.text(reason), findsOneWidget);
      expect(find.byType(CtActionTextButton), findsOneWidget);
    });
  });
}
