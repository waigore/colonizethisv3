import 'package:colonizethis_app/features/game/widgets/unit_orders/home_fleet_cargo_consequence.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  test('cargoHoldsForTypeCounts sums catalog cargoHold', () {
    expect(cargoHoldsForTypeCounts(const {'carrack': 1}), 3);
    expect(cargoHoldsForTypeCounts(const {'carrack': 1, 'fluyte': 2}), 11);
    expect(cargoHoldsForTypeCounts(const {'sloop': 2}), 0);
  });

  test('reliable used colours muted / accent / danger', () {
    expect(
      homeFleetSplitCargoLineColor(
        remainingHolds: 4,
        overseasUsed: 2,
        isCargoUsedReliable: true,
        cargoNotDefined: false,
      ),
      EditorialMonoclePalette.muted,
    );
    expect(
      homeFleetSplitCargoLineColor(
        remainingHolds: 2,
        overseasUsed: 2,
        isCargoUsedReliable: true,
        cargoNotDefined: false,
      ),
      EditorialMonoclePalette.accent,
    );
    expect(
      homeFleetSplitCargoLineColor(
        remainingHolds: 1,
        overseasUsed: 2,
        isCargoUsedReliable: true,
        cargoNotDefined: false,
      ),
      EditorialMonoclePalette.danger,
    );
  });

  test('unreliable or notDefined used is never a shortfall colour', () {
    expect(
      homeFleetSplitCargoLineColor(
        remainingHolds: 0,
        overseasUsed: 9,
        isCargoUsedReliable: false,
        cargoNotDefined: false,
      ),
      EditorialMonoclePalette.muted,
    );
    expect(
      homeFleetSplitCargoLineColor(
        remainingHolds: 0,
        overseasUsed: 9,
        isCargoUsedReliable: true,
        cargoNotDefined: true,
      ),
      EditorialMonoclePalette.muted,
    );
  });

  test('used label is em dash when unreliable or not defined', () {
    expect(
      homeFleetSplitCargoUsedLabel(
        overseasUsed: 3,
        isCargoUsedReliable: false,
        cargoNotDefined: false,
      ),
      '—',
    );
    final l10n = AppLocalizationsEn();
    expect(
      homeFleetSplitCargoLineText(
        l10n: l10n,
        remainingHolds: 3,
        overseasUsed: 2,
        isCargoUsedReliable: false,
        cargoNotDefined: false,
      ),
      contains('—'),
    );
  });
}
