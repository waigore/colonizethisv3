import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_data/colonizethis_data.dart' show kTechIdTradeFairs;
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

import 'diplomacy_game_fixtures_scenarios_gp_tribe.dart';

void main() {
  group('relationMeterStepLabel', () {
    test('returns the 10-word ladder in hostile → friendly order', () {
      expect(relationMeterStepLabels.length, relationMeterStepCount);
      expect(relationMeterStepLabel(1), 'Hostile');
      expect(relationMeterStepLabel(2), 'Antagonistic');
      expect(relationMeterStepLabel(3), 'Distrustful');
      expect(relationMeterStepLabel(4), 'Unfriendly');
      expect(relationMeterStepLabel(5), 'Wary');
      expect(relationMeterStepLabel(6), 'Neutral');
      expect(relationMeterStepLabel(7), 'Cordial');
      expect(relationMeterStepLabel(8), 'Amicable');
      expect(relationMeterStepLabel(9), 'Friendly');
      expect(relationMeterStepLabel(10), 'Devoted');
    });
    test('ladder words are all distinct', () {
      expect(relationMeterStepLabels.toSet().length, relationMeterStepCount);
    });
    test('clamps out-of-range steps to the nearest end word', () {
      expect(relationMeterStepLabel(0), 'Hostile');
      expect(relationMeterStepLabel(-3), 'Hostile');
      expect(relationMeterStepLabel(11), 'Devoted');
    });
  });
}
