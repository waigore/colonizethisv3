// Widget tests for map-shell labour/feeding indicator (Refs #4506).
// SPEC: SPEC/ui/empire-overview.md § Labour and feeding indicator.
// Colour resolution (numeric token) pins.

import 'package:colonizethis_app/features/game/widgets/shell/labour_feeding_indicator_support.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'labour_feeding_indicator_test_support.dart';

void main() {
  suppressLogsForTests();

  group('labourFeedingNumericColor (Refs #4506)', () {
    test('full capacity and fully fed forces resolve muted', () {
      expect(
        labourFeedingNumericColor(
          labourReadiness: labourFeedingFullLabour,
          forcesFeeding: labourFeedingFullyFedForces,
          notDefined: false,
        ),
        EditorialMonoclePalette.muted,
      );
    });

    test('reduced labour resolves accent', () {
      expect(
        labourFeedingNumericColor(
          labourReadiness: labourFeedingReducedLabour,
          forcesFeeding: labourFeedingFullyFedForces,
          notDefined: false,
        ),
        EditorialMonoclePalette.accent,
      );
    });

    test('zero labour with non-empty pool resolves danger', () {
      expect(
        labourFeedingNumericColor(
          labourReadiness: labourFeedingZeroLabour,
          forcesFeeding: labourFeedingFullyFedForces,
          notDefined: false,
        ),
        EditorialMonoclePalette.danger,
      );
    });

    test('underfed forces resolve danger even at full labour', () {
      expect(
        labourFeedingNumericColor(
          labourReadiness: labourFeedingFullLabour,
          forcesFeeding: labourFeedingUnderfedLandForces,
          notDefined: false,
        ),
        EditorialMonoclePalette.danger,
      );
    });

    test('empty pool with no underfed forces resolves muted', () {
      expect(
        labourFeedingNumericColor(
          labourReadiness: labourFeedingEmptyPoolLabour,
          forcesFeeding: labourFeedingFullyFedForces,
          notDefined: false,
        ),
        EditorialMonoclePalette.muted,
      );
    });

    test('reduced labour with underfed forces resolves danger', () {
      expect(
        labourFeedingNumericColor(
          labourReadiness: labourFeedingReducedLabour,
          forcesFeeding: labourFeedingUnderfedLandForces,
          notDefined: false,
        ),
        EditorialMonoclePalette.danger,
      );
    });

    test('empty pool with underfed forces resolves danger', () {
      expect(
        labourFeedingNumericColor(
          labourReadiness: labourFeedingEmptyPoolLabour,
          forcesFeeding: labourFeedingUnderfedLandForces,
          notDefined: false,
        ),
        EditorialMonoclePalette.danger,
      );
    });
  });
}
