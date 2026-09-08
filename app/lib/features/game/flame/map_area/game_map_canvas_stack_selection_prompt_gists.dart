/// Work-target selection banner payoff gist lines. Refs #4747.
library;

import 'package:flutter/material.dart';

import '../../widgets/units/civilian/build_fort_payoff_gist_line.dart';
import '../../widgets/units/civilian/build_improvement_next_yield_gist_line.dart';
import '../../widgets/units/civilian/explore_payoff_gist_line.dart';
import '../../widgets/units/civilian/prospect_payoff_gist_line.dart';
import '../../widgets/units/civilian/purchase_land_payoff_gist_line.dart';
import '../../widgets/units/civilian/transport_step_yield_gist_line.dart';
import '../../widgets/units/civilian/upgrade_town_payoff_gist_line.dart';

/// After-this-work gist family shown under the selection-prompt header.
class GameMapSelectionPromptPayoffGists extends StatelessWidget {
  const GameMapSelectionPromptPayoffGists({
    this.nextYieldGist,
    this.payoffGist,
    this.transportGist,
    this.buildFortGist,
    this.exploreGist,
    this.prospectGist,
    this.upgradeTownGist,
    super.key,
  });

  final String? nextYieldGist;
  final String? payoffGist;
  final String? transportGist;
  final String? buildFortGist;
  final String? exploreGist;
  final String? prospectGist;
  final String? upgradeTownGist;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nextYieldGist != null && nextYieldGist!.isNotEmpty)
          BuildImprovementYieldGistLine(text: nextYieldGist!),
        if (payoffGist != null && payoffGist!.isNotEmpty)
          PurchaseLandPayoffGistLine(text: payoffGist!),
        if (transportGist != null && transportGist!.isNotEmpty)
          TransportStepYieldGistLine(text: transportGist!),
        if (buildFortGist != null && buildFortGist!.isNotEmpty)
          BuildFortPayoffGistLine(text: buildFortGist!),
        if (exploreGist != null && exploreGist!.isNotEmpty)
          ExplorePayoffGistLine(text: exploreGist!),
        if (prospectGist != null && prospectGist!.isNotEmpty)
          ProspectPayoffGistLine(text: prospectGist!),
        if (upgradeTownGist != null && upgradeTownGist!.isNotEmpty)
          UpgradeTownPayoffGistLine(text: upgradeTownGist!),
      ],
    );
  }
}
