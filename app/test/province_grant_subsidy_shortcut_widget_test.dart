// Pins MAP20001 Political Grant Aid / Set Subsidy widget copy (Refs #4761).

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_grant_subsidy_props.dart';

import 'province_grant_subsidy_shortcut_fixtures.dart';
import 'province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  group('Political Grant Aid / Set Subsidy widget', () {
    testWidgets('renders both labels under Owner when shown', (tester) async {
      final game = buildGrantSubsidyShortcutGame(ownerId: kGrantSubsidyMinorId);
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: kGrantSubsidyProvinceId,
          selectedTileKey: kGrantSubsidyTileKey,
          grantSubsidy: (
            showGrantAid: true,
            grantAidEnabled: true,
            grantAidPending: false,
            grantAidRejectionReason: null,
            onGrantAidTap: () {},
            showSetSubsidy: true,
            setSubsidyEnabled: true,
            setSubsidyPending: false,
            setSubsidyRejectionReason: null,
            onSetSubsidyTap: () {},
          ),
        ),
      );
      expect(find.text(l10n.provinceOverlay_grantAidAction), findsOneWidget);
      expect(find.text(l10n.provinceOverlay_setSubsidyAction), findsOneWidget);
      expect(
        find.text(l10n.provinceOverlay_establishEmbassyAction),
        findsNothing,
      );
    });

    testWidgets('pending Grant Aid shows Cancel', (tester) async {
      final game = buildGrantSubsidyShortcutGame(ownerId: kGrantSubsidyMinorId);
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: kGrantSubsidyProvinceId,
          selectedTileKey: kGrantSubsidyTileKey,
          grantSubsidy: (
            showGrantAid: true,
            grantAidEnabled: true,
            grantAidPending: true,
            grantAidRejectionReason: null,
            onGrantAidTap: () {},
            showSetSubsidy: true,
            setSubsidyEnabled: true,
            setSubsidyPending: false,
            setSubsidyRejectionReason: null,
            onSetSubsidyTap: () {},
          ),
        ),
      );
      expect(
        find.text(l10n.provinceOverlay_cancelGrantAidAction),
        findsOneWidget,
      );
      expect(find.text(l10n.provinceOverlay_setSubsidyAction), findsOneWidget);
    });

    testWidgets('pending Set Subsidy shows Cancel', (tester) async {
      final game = buildGrantSubsidyShortcutGame(ownerId: kGrantSubsidyMinorId);
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: kGrantSubsidyProvinceId,
          selectedTileKey: kGrantSubsidyTileKey,
          grantSubsidy: (
            showGrantAid: true,
            grantAidEnabled: true,
            grantAidPending: false,
            grantAidRejectionReason: null,
            onGrantAidTap: () {},
            showSetSubsidy: true,
            setSubsidyEnabled: true,
            setSubsidyPending: true,
            setSubsidyRejectionReason: null,
            onSetSubsidyTap: () {},
          ),
        ),
      );
      expect(find.text(l10n.provinceOverlay_grantAidAction), findsOneWidget);
      expect(
        find.text(l10n.provinceOverlay_cancelSetSubsidyAction),
        findsOneWidget,
      );
    });

    testWidgets('hidden when control flags are false', (tester) async {
      final game = buildGrantSubsidyShortcutGame(
        ownerId: kGrantSubsidyHumanPlayerId,
        asMinor: false,
      );
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: kGrantSubsidyProvinceId,
          selectedTileKey: kGrantSubsidyTileKey,
        ),
      );
      expect(find.text(l10n.provinceOverlay_grantAidAction), findsNothing);
      expect(find.text(l10n.provinceOverlay_setSubsidyAction), findsNothing);
    });

    testWidgets('narrow disabled Grant Aid shows inline reason', (
      tester,
    ) async {
      final game = buildGrantSubsidyShortcutGame(ownerId: kGrantSubsidyMinorId);
      const reason = 'Insufficient treasury for GrantAid (need 1000)';
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: buildProvinceOverlayDarkThemeShell(
            game: game,
            displayId: kGrantSubsidyProvinceId,
            selectedTileKey: kGrantSubsidyTileKey,
            grantSubsidy: (
              showGrantAid: true,
              grantAidEnabled: false,
              grantAidPending: false,
              grantAidRejectionReason: reason,
              onGrantAidTap: null,
              showSetSubsidy: true,
              setSubsidyEnabled: true,
              setSubsidyPending: false,
              setSubsidyRejectionReason: null,
              onSetSubsidyTap: () {},
            ),
          ),
        ),
      );
      expect(find.text(reason), findsOneWidget);
      expect(find.byType(CtActionTextButton), findsNWidgets(2));
    });
  });
}
