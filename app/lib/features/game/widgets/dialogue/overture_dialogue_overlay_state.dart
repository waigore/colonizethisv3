import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/ct_full_screen_dialogue_shell.dart';
import '../../../../../widgets/ct_loading_indicator.dart';
import '../../../../../widgets/ct_nine_patch_button.dart';
import '../../../../../widgets/ct_spacing.dart';
import 'ct_dialogue_line_choice_body.dart';
import 'ct_dialogue_view.dart';
import 'dialogue_tristate_decision_row.dart';
import 'overture_dialogue_overlay.dart';
import 'overture_dialogue_overlay_flow.dart';
import 'overture_dialogue_overlay_phase_two.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart';
import 'package:colonizethis_logic/src/turn_to_year.dart';
import 'package:colonizethis_logic/src/civilians/spy_relocate_intel.dart';
import 'package:colonizethis_logic/src/civilians/civilians_missing_work_orders.dart';

class OvertureDialogueOverlayState extends State<OvertureDialogueOverlay>
    with OvertureDialogueOverlayFlow {
  @override
  bool overtureIntroDone = false;
  @override
  CtDialogueView? overtureView;
  @override
  Object? overtureLoadError;

  /// Per-offer decisions; `null` means the player has not yet tapped Accept
  /// or Reject on that row. The Submit button stays disabled until every
  /// entry is non-null (issue #2867 R23 / AC4).
  late List<bool?> _accepted;

  @override
  void initState() {
    super.initState();
    _accepted = List<bool?>.filled(widget.pendingOvertures.length, null);
    if (widget.skipIntroForTest) {
      overtureIntroDone = true;
    } else {
      loadAndRunOvertureIntro();
    }
  }

  void _updateOvertureDecision(int index, bool? next) {
    setState(() => _accepted[index] = next);
  }

  bool get _allDecided => dialogueTristateAllDecided(_accepted);

  String _offererDisplayName(String offererGpId) {
    for (final p in widget.game.players) {
      if (p.id == offererGpId) return p.displayName;
    }
    return offererGpId;
  }

  String _stageLabel(AppLocalizations l10n, OvertureStage stage) {
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

  void _submit() {
    final decisions = <OvertureDecision>[];
    for (var i = 0; i < widget.pendingOvertures.length; i++) {
      final offer = widget.pendingOvertures[i];
      decisions.add(
        OvertureDecision(
          offererGpId: offer.offererGpId,
          targetFactionId: offer.targetFactionId,
          stage: offer.stage,
          accepted: _accepted[i] ?? true,
        ),
      );
    }
    widget.onDecisions(decisions);
  }

  void _submitErrorFallback() {
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

  @override
  Widget build(BuildContext context) {
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
              onPressed: _submitErrorFallback,
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
        accepted: _accepted,
        offererDisplayName: _offererDisplayName,
        stageLabel: _stageLabel,
        allDecided: _allDecided,
        onSubmit: _submit,
        onDecisionChanged: _updateOvertureDecision,
      ),
    );
  }
}
