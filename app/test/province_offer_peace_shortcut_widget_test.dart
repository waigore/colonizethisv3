// Pins MAP20001 Political owner standing + Offer Peace widget (Refs #4479).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md — Political standing / Offer Peace.
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_constants.dart'
    show kDiplomacyAllianceBadgeLabel;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_offer_peace_shortcut_test_support.dart';
import 'province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();

  group('Political standing / Offer Peace widget', () {
    testWidgets('renders At war and Offer Peace when shown', (tester) async {
      final game = offerPeaceBuildGame(
        ownerId: offerPeaceRivalId,
        relationState: RelationState.atWar,
      );
      final l10n = AppLocalizationsEn();
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: offerPeaceProvinceId,
          selectedTileKey: offerPeaceTileKey,
          omniscientDetail: true,
          showOwnerStanding: true,
          ownerStandingAtWar: true,
          showOfferPeaceControl: true,
          offerPeaceEnabled: true,
          onOfferPeaceTap: () {},
        ),
      );
      await tester.pump();
      expect(
        find.text(l10n.provinceOverlay_ownerStandingAtWar),
        findsOneWidget,
      );
      expect(find.text(l10n.provinceOverlay_offerPeaceAction), findsOneWidget);
      expect(find.text('AT_WAR'), findsNothing);
    });

    testWidgets('renders At peace without Offer Peace; ALLIANCE when allied', (
      tester,
    ) async {
      final game = offerPeaceBuildGame(
        ownerId: offerPeaceRivalId,
        formalAlliance: true,
      );
      final l10n = AppLocalizationsEn();
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: offerPeaceProvinceId,
          selectedTileKey: offerPeaceTileKey,
          omniscientDetail: true,
          showOwnerStanding: true,
          ownerStandingAtWar: false,
          showOwnerAllianceBadge: true,
          showOfferPeaceControl: false,
        ),
      );
      await tester.pump();
      expect(
        find.text(l10n.provinceOverlay_ownerStandingAtPeace),
        findsOneWidget,
      );
      expect(find.text(l10n.provinceOverlay_offerPeaceAction), findsNothing);
      expect(find.text(kDiplomacyAllianceBadgeLabel), findsOneWidget);
    });

    testWidgets('pending shows Cancel', (tester) async {
      final game = offerPeaceBuildGame(
        ownerId: offerPeaceRivalId,
        relationState: RelationState.atWar,
      );
      final l10n = AppLocalizationsEn();
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          displayId: offerPeaceProvinceId,
          selectedTileKey: offerPeaceTileKey,
          omniscientDetail: true,
          showOwnerStanding: true,
          ownerStandingAtWar: true,
          showOfferPeaceControl: true,
          offerPeaceEnabled: true,
          offerPeacePending: true,
          onOfferPeaceTap: () {},
        ),
      );
      await tester.pump();
      expect(
        find.text(l10n.provinceOverlay_cancelOfferPeaceAction),
        findsOneWidget,
      );
    });
  });
}
