// Table-driven town-work prefilter scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_work_tile_prefilter_town_work_run_rows.dart';

/// One row in [orderSuggestionWorkTilePrefilterTownWorkScenarios].
class OrderSuggestionWorkTilePrefilterTownWorkScenario
    implements LabeledScenario {
  const OrderSuggestionWorkTilePrefilterTownWorkScenario({
    required this.label,
    required this.run,
  });

  @override
  final String label;
  final void Function() run;
}

void runOrderSuggestionWorkTilePrefilterTownWorkScenario(
  OrderSuggestionWorkTilePrefilterTownWorkScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionWorkTilePrefilterTownWorkScenario>
orderSuggestionWorkTilePrefilterTownWorkScenarios() => const [
  OrderSuggestionWorkTilePrefilterTownWorkScenario(
    label:
        'upgrade_town includes town tiles only in owned provinces with a town',
    run: oswttwRunUpgradeTownOwnedOnly,
  ),
  OrderSuggestionWorkTilePrefilterTownWorkScenario(
    label:
        'build_fort matches upgrade_town town-tile prefilter for shared owned set',
    run: oswttwRunBuildFortMatchesUpgradeTown,
  ),
  OrderSuggestionWorkTilePrefilterTownWorkScenario(
    label:
        'default path derives owned provinces from ProvinceOwnerCache '
        '(Phase 6b)',
    run: oswttwRunDefaultPathUsesProvinceOwnerCache,
  ),
];
