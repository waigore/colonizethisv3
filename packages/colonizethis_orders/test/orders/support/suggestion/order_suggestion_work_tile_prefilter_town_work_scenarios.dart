// Table-driven town-work prefilter scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_work_tile_prefilter_town_work_expectations.dart';

/// One row in [orderSuggestionWorkTilePrefilterTownWorkScenarios].
class OrderSuggestionWorkTilePrefilterTownWorkScenario implements LabeledScenario {
  const OrderSuggestionWorkTilePrefilterTownWorkScenario({
    required this.label,
    required this.target,
  });

  @override
  final String label;
  final OrderSuggestionWorkTilePrefilterTownWorkTarget target;
}

void runOrderSuggestionWorkTilePrefilterTownWorkScenario(
  OrderSuggestionWorkTilePrefilterTownWorkScenario scenario,
) {
  runOrderSuggestionWorkTilePrefilterTownWorkExpectation(scenario.target);
}

List<OrderSuggestionWorkTilePrefilterTownWorkScenario>
    orderSuggestionWorkTilePrefilterTownWorkScenarios() => const [
          OrderSuggestionWorkTilePrefilterTownWorkScenario(
            label:
                'upgrade_town includes town tiles only in owned provinces with a town',
            target: OrderSuggestionWorkTilePrefilterTownWorkTarget.upgradeTownOwnedOnly,
          ),
          OrderSuggestionWorkTilePrefilterTownWorkScenario(
            label:
                'build_fort matches upgrade_town town-tile prefilter for shared owned set',
            target:
                OrderSuggestionWorkTilePrefilterTownWorkTarget.buildFortMatchesUpgradeTown,
          ),
          OrderSuggestionWorkTilePrefilterTownWorkScenario(
            label: 'default path derives owned provinces from ProvinceOwnerCache '
                '(Phase 6b)',
            target: OrderSuggestionWorkTilePrefilterTownWorkTarget
                .defaultPathUsesProvinceOwnerCache,
          ),
        ];
