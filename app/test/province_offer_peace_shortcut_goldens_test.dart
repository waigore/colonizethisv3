// Visual goldens for MAP20001 Political owner standing + Offer Peace (Refs #4479).

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_constants.dart'
    show kDiplomacyAllianceBadgeLabel;
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_offer_peace_shortcut_goldens_cases.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  for (final c in provinceOfferPeaceStandingWideCases) {
    testWidgets('golden: ${c.name} (Refs #4479)', (WidgetTester tester) async {
      final boundaryKey = ValueKey<String>(
        'province_standing_${c.name}_golden',
      );
      await pumpProvinceOfferPeaceStandingGolden(
        tester,
        boundaryKey: boundaryKey,
        surface: const Size(640, 720),
        overlaySize: const Size(460, 680),
        c: c,
      );
      expect(tester.takeException(), isNull);
      if (c.showStanding) {
        expect(
          find.text(
            c.atWar
                ? l10n.provinceOverlay_ownerStandingAtWar
                : l10n.provinceOverlay_ownerStandingAtPeace,
          ),
          findsOneWidget,
        );
      }
      if (c.showAlliance) {
        expect(find.text(kDiplomacyAllianceBadgeLabel), findsOneWidget);
      }
      if (c.showOfferPeace) {
        final finder = find.widgetWithText(
          CtActionTextButton,
          c.offerPeacePending
              ? l10n.provinceOverlay_cancelOfferPeaceAction
              : l10n.provinceOverlay_offerPeaceAction,
        );
        expect(finder, findsOneWidget);
        await tester.ensureVisible(finder);
        await tester.pump();
      }
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    });
  }

  testWidgets(
    'golden: standing + Offer Peace wraps at 320 dp (Refs #4479)',
    (WidgetTester tester) async {
      const c = ProvinceOfferPeaceStandingGoldenCase(
        name: 'at war 320',
        goldenFile: 'goldens/province_overlay_owner_standing_at_war_320.png',
        showStanding: true,
        atWar: true,
        showOfferPeace: true,
        offerPeaceEnabled: true,
      );
      const boundaryKey = ValueKey<String>('province_standing_320_golden');
      await pumpProvinceOfferPeaceStandingGolden(
        tester,
        boundaryKey: boundaryKey,
        surface: const Size(320, 720),
        overlaySize: const Size(300, 680),
        c: c,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.provinceOverlay_ownerStandingAtWar), findsOneWidget);
      expect(
        find.widgetWithText(
          CtActionTextButton,
          l10n.provinceOverlay_offerPeaceAction,
        ),
        findsOneWidget,
      );
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    },
  );
}
