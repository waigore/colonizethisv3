import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import '../support/dossier_test_support.dart';
import 'dossier_get_dossier_cases.dart';

void main() {
  group('suspicionBandFromScore', () {
    test('0-2 returns unknown', () {
      expect(suspicionBandFromScore(0), SuspicionBand.unknown);
      expect(suspicionBandFromScore(2), SuspicionBand.unknown);
    });
    test('3-5 returns possible', () {
      expect(suspicionBandFromScore(3), SuspicionBand.possible);
      expect(suspicionBandFromScore(5), SuspicionBand.possible);
    });
    test('6-8 returns likely', () {
      expect(suspicionBandFromScore(6), SuspicionBand.likely);
      expect(suspicionBandFromScore(8), SuspicionBand.likely);
    });
    test('9-10 returns almostCertain', () {
      expect(suspicionBandFromScore(9), SuspicionBand.almostCertain);
      expect(suspicionBandFromScore(10), SuspicionBand.almostCertain);
    });
    test('above 10 returns confirmed', () {
      expect(suspicionBandFromScore(11), SuspicionBand.confirmed);
    });
  });

  registerDossierGetDossierCases();

}
