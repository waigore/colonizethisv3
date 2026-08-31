// Scenario table for diplomacy confirm first-order preview pins (Refs #4181, #4305).

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_panel_confirm_preview_test_fixtures.dart';
import 'diplomacy_panel_orders_pump_support.dart';
import 'diplomacy_panel_test_support.dart';
import 'panel_test_fixtures.dart';

typedef DiplomacyConfirmPreviewCase = ({
  String name,
  Game Function() game,
  Finder Function() actionFinder,
  bool minorsTab,
  void Function(String body) assertBody,
});

List<DiplomacyConfirmPreviewCase> diplomacyConfirmPreviewCases() => [
      (
        name: 'Offer Peace confirm includes conditional peace preview (Refs #4181)',
        game: buildDiplomacyRichPanelTestGame,
        actionFinder: () {
          final gp3Row = find.byKey(
            const ValueKey('${kDiplomacyRowBodyKeyPrefix}gp3'),
          );
          return find.descendant(of: gp3Row, matching: find.text('Offer Peace'));
        },
        minorsTab: false,
        assertBody: (body) {
          expect(body.toLowerCase(), contains('peace'));
          expect(body.toLowerCase(), contains('accept'));
          expect(body, isNot(contains('When:')));
        },
      ),
      (
        name: 'Alliance confirm includes treaty preview (Refs #4181)',
        game: buildDiplomacyPanelTestGame,
        actionFinder: () => find.text('Alliance'),
        minorsTab: false,
        assertBody: (body) {
          expect(body, contains('No treasury charge'));
          expect(body.toLowerCase(), contains('treaty'));
          expect(body, isNot(contains('When:')));
        },
      ),
      (
        name: 'Embassy confirm shows paid overture preview (Refs #4181)',
        game: diplomacyConfirmPreviewMinorEmbassyOvertureGame,
        actionFinder: () => find.descendant(
          of: diplomacyMinorRow(),
          matching: find.text('Embassy'),
        ),
        minorsTab: true,
        assertBody: (body) {
          expect(body, contains('£$overtureEmbassyCost'));
          expect(body.toLowerCase(), contains('grant aid'));
          expect(body.toLowerCase(), contains('purchase land'));
        },
      ),
      (
        name: 'NAP confirm shows free pact preview (Refs #4181)',
        game: diplomacyConfirmPreviewMinorNapOvertureGame,
        actionFinder: () => find.descendant(
          of: diplomacyMinorRow(),
          matching: find.text('NAP'),
        ),
        minorsTab: true,
        assertBody: (body) {
          expect(body, contains('No treasury charge'));
          expect(body.toLowerCase(), contains('join empire'));
          expect(body.toLowerCase(), contains('declare war'));
          expect(body, isNot(contains('When:')));
        },
      ),
      (
        name: 'Establish Favored partner confirm shows matching preview (Refs #4586)',
        game: diplomacyConfirmPreviewFtpGame,
        actionFinder: () => find.text('Establish Favored partner'),
        minorsTab: false,
        assertBody: (body) {
          expect(body, contains('No treasury charge'));
          expect(body, contains('Favored Trading Partners'));
          expect(body, contains('same bid rank'));
          expect(body, isNot(contains('When:')));
        },
      ),
      (
        name: 'Boycott confirm shows colony embargo preview (Refs #4181)',
        game: diplomacyConfirmPreviewColonyBoycottGame,
        actionFinder: () => find.text('Boycott'),
        minorsTab: false,
        assertBody: (body) {
          expect(body, contains('No treasury charge'));
          expect(body, contains('will not fill in either direction'));
          expect(body.toLowerCase(), contains('purchase land'));
          expect(body.toLowerCase(), contains('grant aid'));
          expect(body.toLowerCase(), contains('cancelled'));
          expect(body, contains('Aztec'));
          expect(body, isNot(contains('t1')));
          expect(body, isNot(contains('-50')));
          expect(body, isNot(contains('When:')));
        },
      ),
      (
        name: 'Revoke Boycott confirm ends embargo preview (Refs #4181)',
        game: () => diplomacyConfirmPreviewColonyBoycottGame(
          boycotts: const [
            BoycottState(
              gpId: diplomacyOrdersHumanId,
              targetGpId: diplomacyOrdersGp2,
              sinceTurn: 1,
            ),
          ],
        ),
        actionFinder: () => find.text('Revoke Boycott'),
        minorsTab: false,
        assertBody: (body) {
          expect(body, contains('No treasury charge'));
          expect(body.toLowerCase(), contains('embargo'));
          expect(body.toLowerCase(), contains('purchase land'));
          expect(body.toLowerCase(), contains('grant aid'));
          expect(body, contains('Aztec'));
          expect(body, isNot(contains('t1')));
          expect(body, isNot(contains('When:')));
        },
      ),
    ];
