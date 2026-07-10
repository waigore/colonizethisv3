// Table-driven OrderEngine validateDiplomatic scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_validate_diplomatic_run_rows.dart';

class OrderEngineValidateDiplomaticScenario implements RefsScenario {
  const OrderEngineValidateDiplomaticScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runOrderEngineValidateDiplomaticScenario(
  OrderEngineValidateDiplomaticScenario scenario,
) => scenario.run();

List<OrderEngineValidateDiplomaticScenario>
orderEngineValidateDiplomaticScenarios() => const [
  // dart format off
          OrderEngineValidateDiplomaticScenario(
            label: 'declareWar rejected when already at war',
            run: vedRunDeclareWarRejectedWhenAlreadyAtWar,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'offerPeace rejected when not at war',
            run: vedRunOfferPeaceRejectedWhenNotAtWar,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'establishOverture rejected when target is at war with GP',
            run: vedRunEstablishOvertureRejectedWhenTargetIsAtWarWithGp,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'establishOverture trade consulate rejected without diplomatic_expertise',
            run: vedRunEstablishOvertureTradeConsulateRejectedWithoutDiplomaticExpertise,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'establishOverture consulate rejected when treasury too low',
            run: vedRunEstablishOvertureConsulateRejectedWhenTreasuryTooLow,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'establishOverture embassy requires existing consulate',
            run: vedRunEstablishOvertureEmbassyRequiresExistingConsulate,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'establishOverture second order for same faction in same turn rejected',
            run: vedRunEstablishOvertureSecondOrderForSameFactionInSameTurnRejected,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'second diplomatic order to same target different type is rejected',
            run: vedRunSecondDiplomaticOrderToSameTargetDifferentTypeIsRejected,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'grantAid requires embassy and sufficient treasury',
            run: vedRunGrantAidRequiresEmbassyAndSufficientTreasury,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'grantAid rejects amounts not a multiple of £1000',
            run: vedRunGrantAidRejectsAmountsNotAMultipleOf1000,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'grantAid then setSubsidy toward same target both accepted',
            run: vedRunGrantAidThenSetSubsidyTowardSameTargetBothAccepted,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'setSubsidy requires an embassy (Refs #3753 R2)',
            run: vedRunSetSubsidyRequiresAnEmbassyRefs3753R2,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'setSubsidy with an embassy is accepted regardless of treasury (no upfront cost, Refs #3753 R3)',
            run: vedRunSetSubsidyWithEmbassyAcceptedRegardlessOfTreasuryRefs3753R3,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'setSubsidy with an embassy and a valid percent is accepted',
            run: vedRunSetSubsidyWithEmbassyAndValidPercentAccepted,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'setSubsidy rejects a percent outside 5-20 in steps of 5',
            run: vedRunSetSubsidyRejectsPercentOutside520InStepsOf5,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'second grantAid toward same target rejected',
            run: vedRunSecondGrantAidTowardSameTargetRejected,
          ),
          OrderEngineValidateDiplomaticScenario(
            label: 'declareWar then grantAid toward same target rejected',
            run: vedRunDeclareWarThenGrantAidTowardSameTargetRejected,
          ),
          // dart format on
];
