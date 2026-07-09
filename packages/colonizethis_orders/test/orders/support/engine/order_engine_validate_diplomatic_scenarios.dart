// Table-driven OrderEngine validateDiplomatic scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_validate_diplomatic_expectations.dart';

class OrderEngineValidateDiplomaticScenario implements RefsScenario {
  const OrderEngineValidateDiplomaticScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderEngineValidateDiplomaticTarget target;
  @override
  final String? refs;
}

void runOrderEngineValidateDiplomaticScenario(
  OrderEngineValidateDiplomaticScenario scenario,
) {
  runOrderEngineValidateDiplomaticExpectation(scenario.target);
}

List<OrderEngineValidateDiplomaticScenario>
orderEngineValidateDiplomaticScenarios() => const [
  // dart format off
  OrderEngineValidateDiplomaticScenario(
    label: 'declareWar rejected when already at war',
    target: OrderEngineValidateDiplomaticTarget.declarewarRejectedWhenAlreadyAtWar,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'offerPeace rejected when not at war',
    target: OrderEngineValidateDiplomaticTarget.offerpeaceRejectedWhenNotAtWar,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'establishOverture rejected when target is at war with GP',
    target: OrderEngineValidateDiplomaticTarget.establishovertureRejectedWhenTargetIsAtWarWithGP,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'establishOverture trade consulate rejected without diplomatic_expertise',
    target: OrderEngineValidateDiplomaticTarget.establishovertureTradeConsulateRejectedWithoutDiplomaticExpertise,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'establishOverture consulate rejected when treasury too low',
    target: OrderEngineValidateDiplomaticTarget.establishovertureConsulateRejectedWhenTreasuryTooLow,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'establishOverture embassy requires existing consulate',
    target: OrderEngineValidateDiplomaticTarget.establishovertureEmbassyRequiresExistingConsulate,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'establishOverture second order for same faction in same turn rejected',
    target: OrderEngineValidateDiplomaticTarget.establishovertureSecondOrderForSameFactionInSameTurnRejected,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'second diplomatic order to same target different type is rejected',
    target: OrderEngineValidateDiplomaticTarget.secondDiplomaticOrderToSameTargetDifferentTypeIsRejected,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'grantAid requires embassy and sufficient treasury',
    target: OrderEngineValidateDiplomaticTarget.grantaidRequiresEmbassyAndSufficientTreasury,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'grantAid rejects amounts not a multiple of £1000',
    target: OrderEngineValidateDiplomaticTarget.grantaidRejectsAmountsNotAMultipleOf1000,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'grantAid then setSubsidy toward same target both accepted',
    target: OrderEngineValidateDiplomaticTarget.grantaidThenSetSubsidyTowardSameTargetBothAccepted,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'setSubsidy requires an embassy (Refs #3753 R2)',
    target: OrderEngineValidateDiplomaticTarget.setsubsidyRequiresAnEmbassyRefs3753R2,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'setSubsidy with an embassy is accepted regardless of treasury (no upfront cost, Refs #3753 R3)',
    target: OrderEngineValidateDiplomaticTarget.setsubsidyWithAnEmbassyIsAcceptedRegardlessOfTreasuryNoUpfrontCostRefs3753R3,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'setSubsidy with an embassy and a valid percent is accepted',
    target: OrderEngineValidateDiplomaticTarget.setsubsidyWithAnEmbassyAndAValidPercentIsAccepted,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'setSubsidy rejects a percent outside 5-20 in steps of 5',
    target: OrderEngineValidateDiplomaticTarget.setsubsidyRejectsAPercentOutside520InStepsOf5,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'second grantAid toward same target rejected',
    target: OrderEngineValidateDiplomaticTarget.secondGrantAidTowardSameTargetRejected,
  ),
  OrderEngineValidateDiplomaticScenario(
    label: 'declareWar then grantAid toward same target rejected',
    target: OrderEngineValidateDiplomaticTarget.declarewarThenGrantAidTowardSameTargetRejected,
  ),
  // dart format on
];
