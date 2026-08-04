import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/shell/cargo_hold_indicator_support.dart';

void main() {
  suppressLogsForTests();

  group('cargoHoldNumericColor', () {
    test('normal tier uses muted when below 80% threshold', () {
      expect(
        cargoHoldNumericColor(
          used: 7,
          capacity: 12,
          cargoNotDefined: false,
          isCargoUsedReliable: true,
        ),
        EditorialMonoclePalette.muted,
      );
    });

    test('tight tier uses accent at 80% threshold', () {
      expect(
        cargoHoldNumericColor(
          used: 10,
          capacity: 12,
          cargoNotDefined: false,
          isCargoUsedReliable: true,
        ),
        EditorialMonoclePalette.accent,
      );
    });

    test('full tier uses danger when used equals capacity', () {
      expect(
        cargoHoldNumericColor(
          used: 12,
          capacity: 12,
          cargoNotDefined: false,
          isCargoUsedReliable: true,
        ),
        EditorialMonoclePalette.danger,
      );
    });

    test('over capacity uses danger', () {
      expect(
        cargoHoldNumericColor(
          used: 15,
          capacity: 12,
          cargoNotDefined: false,
          isCargoUsedReliable: true,
        ),
        EditorialMonoclePalette.danger,
      );
    });

    test('zero capacity stays muted', () {
      expect(
        cargoHoldNumericColor(
          used: 0,
          capacity: 0,
          cargoNotDefined: false,
          isCargoUsedReliable: true,
        ),
        EditorialMonoclePalette.muted,
      );
    });

    test('unreliable used stays muted', () {
      expect(
        cargoHoldNumericColor(
          used: 12,
          capacity: 12,
          cargoNotDefined: false,
          isCargoUsedReliable: false,
        ),
        EditorialMonoclePalette.muted,
      );
    });

    test('observe not-defined stays muted', () {
      expect(
        cargoHoldNumericColor(
          used: 12,
          capacity: 12,
          cargoNotDefined: true,
          isCargoUsedReliable: true,
        ),
        EditorialMonoclePalette.muted,
      );
    });
  });
}
