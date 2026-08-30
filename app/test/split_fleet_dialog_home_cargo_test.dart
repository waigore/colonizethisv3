// Home Fleet cargo-consequence line on SplitFleetDialog (Refs #4448).
// Concern split under repo.app_test_file_size (Refs #4013, #4352).

import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'split_fleet_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('home fleet cargo line updates remaining holds vs used', (
    WidgetTester tester,
  ) async {
    final l10n = AppLocalizationsEn();

    await openSplitFleetDialog(
      tester,
      fleet: splitFleetHome(shipTypeIds: const ['carrack', 'fluyte']),
      game: splitFleetCapitalHomeGame(),
      isHomeFleet: true,
      bus: AppEventBus.create(),
      overseasCargoUsed: 4,
    );

    expect(
      find.text(l10n.splitFleet_homeCargoConsequence(7, '4')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.text(l10n.splitFleet_homeCargoConsequence(7, '4')))
          .style
          ?.color,
      EditorialMonoclePalette.muted,
    );

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('fluyte')));
    await tester.pump();
    expect(
      find.text(l10n.splitFleet_homeCargoConsequence(3, '4')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.text(l10n.splitFleet_homeCargoConsequence(3, '4')))
          .style
          ?.color,
      EditorialMonoclePalette.danger,
    );
  });

  testWidgets('home fleet cargo used is em dash when unreliable', (
    WidgetTester tester,
  ) async {
    final l10n = AppLocalizationsEn();

    await openSplitFleetDialog(
      tester,
      fleet: splitFleetHome(shipTypeIds: const ['carrack']),
      game: splitFleetCapitalHomeGame(),
      isHomeFleet: true,
      bus: AppEventBus.create(),
      overseasCargoUsed: 9,
      isCargoUsedReliable: false,
    );

    expect(
      find.text(l10n.splitFleet_homeCargoConsequence(3, '—')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.text(l10n.splitFleet_homeCargoConsequence(3, '—')))
          .style
          ?.color,
      EditorialMonoclePalette.muted,
    );
  });
}
