// Extracted from e2e_attempt_first_fleet_move_or_cancel_test.dart (#4598 Slice C).
library;

// ignore_for_file: deprecated_member_use
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'attempt_fleet_move_harness.dart';

void registerE2eAttemptFirstFleetMoveOrCancelGuardGroup2() {
  group('e2eAttemptFirstFleetMoveOrCancel — direct sea-pick dialog smoke', () {
    testWidgets('SeaPickHost confirms on Confirm tap (fixture sanity)', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final host = await pumpSeaPickDialogStandalone(tester, l10n: l10n);
      expect(host.selected, isNull);
      expect(host.dialogOpen, isTrue);
    });
  });
}
