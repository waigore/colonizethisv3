import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../../widgets/ct_full_screen_dialogue_shell.dart';
import '../../../../../widgets/ct_loading_indicator.dart';
import '../../../../../widgets/ct_nine_patch_button.dart';
import '../../../../../widgets/ct_spacing.dart';
import 'ct_dialogue_line_choice_body.dart';
import 'dialogue_tristate_decision_row.dart';
import 'overture_dialogue_overlay_flow.dart';
import 'overture_dialogue_overlay_phase_two.dart';
import 'overture_dialogue_overlay_widget.dart';

mixin OvertureDialogueOverlayBuild
    on State<OvertureDialogueOverlay>, OvertureDialogueOverlayFlow {
  List<bool?> get accepted;

  void updateOvertureDecision(int index, bool? next);

  bool get allOvertureDecisionsMade => dialogueTristateAllDecided(accepted);

  String offererDisplayName(String offererGpId) {
    for (final p in widget.game.players) {
      if (p.id == offererGpId) return p.displayName;
    }
    return offererGpId;
  }

  String overtureStageLabel(AppLocalizations l10n, OvertureStage stage) {
    switch (stage) {
      case OvertureStage.tradeConsulate:
        return l10n.turnNews_stage_tradeConsulate;
      case OvertureStage.embassy:
        return l10n.turnNews_stage_embassy;
      case OvertureStage.nap:
        return l10n.turnNews_stage_nap;
      case OvertureStage.joinEmpire:
        return l10n.turnNews_stage_joinEmpire;
      case OvertureStage.none:
        return l10n.province_fleetMission_none;
    }
  }

  void submitOvertureDecisions() {
    final decisions = <OvertureDecision>[];
    for (var i = 0; i < widget.pendingOvertures.length; i++) {
      final offer = widget.pendingOvertures[i];
      decisions.add(
        OvertureDecision(
          offererGpId: offer.offererGpId,
          targetFactionId: offer.targetFactionId,
          stage: offer.stage,
          accepted: accepted[i] ?? true,
        ),
      );
    }
    widget.onDecisions(decisions);
  }

  void submitOvertureErrorFallback() {
    final decisions = <OvertureDecision>[];
    for (final OvertureOffer offer in widget.pendingOvertures) {
      decisions.add(
        OvertureDecision(
          offererGpId: offer.offererGpId,
          targetFactionId: offer.targetFactionId,
          stage: offer.stage,
          accepted: true,
        ),
      );
    }
    widget.onDecisions(decisions);
  }

  Widget buildOvertureDialogueOverlay(BuildContext context) {
    final l10n = appL10n(context);
    if (overtureLoadError != null) {
      return CtFullScreenDialogueShell(
        backdrop: widget.child,
        padding: const EdgeInsets.all(CtSpacing.l),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.game_overture_loadError('$overtureLoadError')),
            const SizedBox(height: CtSpacing.l),
            CtNinePatchButton(
              onPressed: submitOvertureErrorFallback,
              child: Text(l10n.game_intervention_continue),
            ),
          ],
        ),
      );
    }

    if (!overtureIntroDone) {
      final view = overtureView;
      return CtFullScreenDialogueShell(
        backdrop: widget.child,
        body: view == null
            ? const CtLoadingIndicator()
            : CtDialogueLineChoiceBody(
                view: view,
                continueLabel: l10n.game_intervention_continue,
                lineTextStyle: Theme.of(context).textTheme.bodyLarge,
                loading: const CtLoadingIndicator(),
              ),
      );
    }

    return CtFullScreenDialogueShell(
      backdrop: widget.child,
      maxHeight: 500,
      body: buildOverturePhaseTwoBody(
        context: context,
        l10n: l10n,
        offers: widget.pendingOvertures,
        accepted: accepted,
        offererDisplayName: offererDisplayName,
        stageLabel: overtureStageLabel,
        allDecided: allOvertureDecisionsMade,
        onSubmit: submitOvertureDecisions,
        onDecisionChanged: updateOvertureDecision,
      ),
    );
  }
}
