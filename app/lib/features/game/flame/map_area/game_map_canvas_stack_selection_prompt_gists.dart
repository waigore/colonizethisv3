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
    final yieldGist = nextYieldGist;
    final landGist = payoffGist;
    final roadGist = transportGist;
    final fortGist = buildFortGist;
    final explorePayoff = exploreGist;
    final prospectPayoff = prospectGist;
    final upgradeTownPayoff = upgradeTownGist;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (yieldGist != null && yieldGist.isNotEmpty)
          BuildImprovementYieldGistLine(text: yieldGist),
        if (landGist != null && landGist.isNotEmpty)
          PurchaseLandPayoffGistLine(text: landGist),
        if (roadGist != null && roadGist.isNotEmpty)
          TransportStepYieldGistLine(text: roadGist),
        if (fortGist != null && fortGist.isNotEmpty)
          BuildFortPayoffGistLine(text: fortGist),
        if (explorePayoff != null && explorePayoff.isNotEmpty)
          ExplorePayoffGistLine(text: explorePayoff),
        if (prospectPayoff != null && prospectPayoff.isNotEmpty)
          ProspectPayoffGistLine(text: prospectPayoff),
        if (upgradeTownPayoff != null && upgradeTownPayoff.isNotEmpty)
          UpgradeTownPayoffGistLine(text: upgradeTownPayoff),
      ],
    );
  }
}
