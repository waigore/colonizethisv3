import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/turn/economy_tech_effects.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('effectiveResearchPointsForTechAllocation', () {
    test(
      'adds 20 percent to military tech when industrial_funding_of_research unlocked',
      () {
        final player = Player(
          id: 'p1',
          displayName: 'P1',
          isHuman: true,
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
      final player = Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        techUnlocked: const {kTechIdIndustrialFundingOfResearch: true},
      );
      final tech = techById(kTechIdCropRotation)!;
      expect(effectiveResearchPointsForTechAllocation(player, tech, 100), 100);
    });
  });
}
