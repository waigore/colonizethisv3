import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'incremental_candidate_validator.dart';
import 'order_suggestion_context.dart';

/// One diplomatic action surfaced on the diplomacy panel with validator-driven
/// enabled state and optional rejection copy for disabled controls.
/// SPEC/ui/diplomacy-panel.md § Per-faction row (disabled-button policy).
class DiplomaticPanelAction {
  const DiplomaticPanelAction({
    required this.order,
    required this.enabled,
    this.rejectionReason,
  });

  final DiplomaticOrder order;
  final bool enabled;
  final String? rejectionReason;
}

/// Canonical panel action order per faction row (deterministic).
const List<OvertureStage> kDiplomaticPanelOvertureStages = <OvertureStage>[
  OvertureStage.tradeConsulate,
  OvertureStage.embassy,
  OvertureStage.nap,
  OvertureStage.joinEmpire,
];

/// Builds the full diplomatic action matrix for [targetId] toward [playerId].
/// Every applicable [DiplomaticOrderType] is enumerated; validity comes from
/// the same incremental diplomatic validator used by order suggestions.
List<DiplomaticOrder> diplomaticPanelActionCandidates({
  required Game game,
  required String playerId,
  required String targetId,
  DiplomacyFactionMembership? factionMembership,
}) {
  if (targetId == playerId) return const <DiplomaticOrder>[];

  final membership = factionMembership ?? DiplomacyFactionMembership.from(game);
  final isGpTarget = isGreatPower(
    game,
    targetId,
    factionMembership: membership,
  );
  final isMinorTribeTarget = isMinorOrTribe(
    game,
    targetId,
    factionMembership: membership,
  );
  if (!isGpTarget && !isMinorTribeTarget) return const <DiplomaticOrder>[];

  final out = <DiplomaticOrder>[
    DiplomaticOrder(
      type: DiplomaticOrderType.declareWar,
      targetFactionId: targetId,
    ),
    DiplomaticOrder(
      type: DiplomaticOrderType.offerPeace,
      targetFactionId: targetId,
    ),
  ];

  if (isGpTarget) {
    out.add(
      DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: targetId,
      ),
    );
  }

  if (isGpTarget || isMinorTribeTarget) {
    for (final stage in kDiplomaticPanelOvertureStages) {
      out.add(
        DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: targetId,
          overtureStage: stage,
        ),
      );
    }
  }

  if (isGpTarget) {
    out.add(
      DiplomaticOrder(
        type: DiplomaticOrderType.establishFtp,
        targetFactionId: targetId,
      ),
    );
  }

  out.addAll(<DiplomaticOrder>[
    DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: targetId,
      amount: grantAidDefaultAmount,
    ),
    DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: targetId,
      amount: kSubsidyPercentDefault,
    ),
  ]);

  // Colony-trade embargo controls (Refs #3753 R6 / R14 / S14). The boycott
  // target is always another Great Power, so these are enumerated on GP rows
  // only; the validator probe (boycottSubValidator / revokeBoycottSubValidator)
  // drives their enabled/disabled state per the disabled-button policy.
  if (isGpTarget) {
    out.addAll(<DiplomaticOrder>[
      DiplomaticOrder(
        type: DiplomaticOrderType.boycott,
        targetFactionId: targetId,
      ),
      DiplomaticOrder(
        type: DiplomaticOrderType.revokeBoycott,
        targetFactionId: targetId,
      ),
    ]);
  }

  return out;
}

/// Enumerates panel actions for [targetId] with enabled/disabled state.
List<DiplomaticPanelAction> enumerateDiplomaticPanelActionsForTarget({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required String targetId,
  required Orders currentOrders,
  IncrementalCandidateValidator? sharedValidator,
  DiplomacyFactionMembership? factionMembership,
}) {
  final candidates = diplomaticPanelActionCandidates(
    game: game,
    playerId: playerId,
    targetId: targetId,
    factionMembership: factionMembership,
  );
  if (candidates.isEmpty) return const <DiplomaticPanelAction>[];

  final validator =
      sharedValidator ??
      buildIncrementalCandidateValidator(
        game: game,
        topology: topology,
        playerId: playerId,
        baseOrders: currentOrders,
        factionMembership: factionMembership,
      );

  return [
    for (final order in candidates) _panelActionFromProbe(validator, order),
  ];
}

DiplomaticPanelAction _panelActionFromProbe(
  IncrementalCandidateValidator validator,
  DiplomaticOrder order,
) {
  final result = validator.probeDiplomaticOrder(order);
  return DiplomaticPanelAction(
    order: order,
    enabled: result.isAccepted,
    rejectionReason: result.isAccepted ? null : result.reason,
  );
}
