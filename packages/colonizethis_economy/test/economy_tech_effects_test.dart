import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_turn/src/turn/economy_tech_effects.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('effectiveResearchPointsForTechAllocation', () {
    test(
      'adds 20 percent to military tech when industrial_funding_of_research unlocked',
      () {
        final player = corePlayer(
          techUnlocked: const {kTechIdIndustrialFundingOfResearch: true},
        );
        final tech = techById(kTechIdOrganisedRegiments)!;
        expect(tech.category, 'military');
        expect(
          effectiveResearchPointsForTechAllocation(player, tech, 100),
          120,
        );
      },
    );

    test('does not boost gathering tech', () {
      final player = corePlayer(
        techUnlocked: const {kTechIdIndustrialFundingOfResearch: true},
      );
      final tech = techById(kTechIdCropRotation)!;
      expect(effectiveResearchPointsForTechAllocation(player, tech, 100), 100);
    });
  });
}
