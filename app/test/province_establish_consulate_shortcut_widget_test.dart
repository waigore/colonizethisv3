// Pins MAP20001 Political Establish Consulate widget copy (Refs #4346, #4642).

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_establish_consulate_shortcut_fixtures.dart';
import 'province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();

  group('Political Establish Consulate widget', () {
    testWidgets('renders Establish Consulate under Owner when shown', (
      tester,
    ) async {
      final l10n = AppLocalizationsEn();
      final game = buildEstablishConsulateShortcutGame(
        ownerId: kEstablishConsulateMinorId,
      );
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: kEstablishConsulateProvinceId,
          selectedTileKey: kEstablishConsulateTileKey,
          showEstablishConsulateControl: true,
          establishConsulateEnabled: true,
          onEstablishConsulateTap: () {},
        ),
      );
      expect(
        find.text(l10n.provinceOverlay_establishConsulateAction),
        findsOneWidget,
      );
      expect(find.textContaining('No consulate with'), findsOneWidget);
    });

    testWidgets('pending shows Cancel label', (tester) async {
      final l10n = AppLocalizationsEn();
      final game = buildEstablishConsulateShortcutGame(
        ownerId: kEstablishConsulateMinorId,
      );
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: kEstablishConsulateProvinceId,
          selectedTileKey: kEstablishConsulateTileKey,
          showEstablishConsulateControl: true,
          establishConsulateEnabled: true,
          establishConsulatePending: true,
          onEstablishConsulateTap: () {},
        ),
      );
      expect(
        find.text(l10n.provinceOverlay_cancelEstablishConsulateAction),
        findsOneWidget,
      );
    });

    testWidgets('hidden when control flag false', (tester) async {
      final l10n = AppLocalizationsEn();
      final game = buildEstablishConsulateShortcutGame(
        ownerId: kEstablishConsulateHumanPlayerId,
        asMinor: false,
      );
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: kEstablishConsulateProvinceId,
          selectedTileKey: kEstablishConsulateTileKey,
        ),
      );
      expect(
        find.text(l10n.provinceOverlay_establishConsulateAction),
        findsNothing,
      );
    });

    testWidgets('narrow disabled shows inline rejection reason', (
      tester,
    ) async {
      final game = buildEstablishConsulateShortcutGame(
        ownerId: kEstablishConsulateMinorId,
      );
      const reason = 'Need Diplomatic Expertise';
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: buildProvinceOverlayDarkThemeShell(
            game: game,
            displayId: kEstablishConsulateProvinceId,
            selectedTileKey: kEstablishConsulateTileKey,
            showEstablishConsulateControl: true,
            establishConsulateEnabled: false,
            establishConsulateRejectionReason: reason,
          ),
        ),
      );
      expect(find.text(reason), findsOneWidget);
      final btn = find.byType(CtActionTextButton);
      expect(btn, findsOneWidget);
    });
  });
}
