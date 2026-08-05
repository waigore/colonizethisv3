import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';

import '../../../../../widgets/ct_loading_indicator.dart';
import '../../../../../widgets/ct_nine_patch_button.dart';
import '../../../../../widgets/ct_spacing.dart';
import 'ct_dialogue_line_choice_body.dart';
import 'ct_dialogue_view.dart';
import 'intervention_choice_buttons.dart';
import 'intervention_dialogue_overlay.dart';
import 'intervention_dialogue_overlay_flow.dart';
import 'intervention_dialogue_overlay_shell.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';

class InterventionDialogueOverlayState extends State<InterventionDialogueOverlay>
    with InterventionDialogueOverlayFlow {
  @override
  YarnProject? interventionProject;
  @override
  DialogueRunner? interventionRunner;
  @override
  CtDialogueView? interventionView;
  @override
  Object? interventionLoadError;
  @override
  bool interventionYarnUiActive = false;
  @override
  bool interventionAwaitingChoice = false;
  @override
  Completer<InterventionChoice>? interventionChoiceCompleter;
  @override
  final List<InterventionDecision> interventionDecisions = [];
  @override
  int interventionPromptIndex = 0;

  @override
  void initState() {
    super.initState();
    unawaited(runInterventionFlow());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    if (interventionLoadError != null) {
      return buildInterventionScrimmedShell(
        context: context,
        bodyChildren: [
          Text(
            l10n.game_intervention_loadError(interventionLoadError.toString()),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: CtSpacing.l),
          Text(
            l10n.game_intervention_degradedHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: CtSpacing.l),
          Align(
            alignment: Alignment.centerRight,
            child: CtNinePatchButton(
              onPressed: degradedSubmitInterventionDoNothing,
              child: Text(l10n.game_intervention_continue),
            ),
          ),
        ],
        bodyPadding: const EdgeInsets.all(CtSpacing.l),
      );
    }

    if (interventionProject == null ||
        interventionRunner == null ||
        interventionView == null) {
      return buildInterventionScrimmedShell(
        context: context,
        bodyChildren: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: CtSpacing.m),
            child: Align(
              alignment: Alignment.center,
              child: CtLoadingIndicator(),
            ),
          ),
        ],
      );
    }

    if (interventionYarnUiActive) {
      return buildInterventionScrimmedShell(
        context: context,
        bodyChildren: [
          CtDialogueLineChoiceBody(
            view: interventionView!,
            continueLabel: l10n.game_intervention_continue,
            lineTextStyle: Theme.of(context).textTheme.bodyLarge,
            loading: const Align(
              alignment: Alignment.center,
              child: CtLoadingIndicator(),
            ),
          ),
        ],
      );
    } else if (interventionAwaitingChoice) {
      final prompt = widget.prompts[interventionPromptIndex];
      final aggressorName =
          interventionFactionDisplayName(widget.game, prompt.aggressorGpId);
      final defenderName = interventionFactionDisplayName(
        widget.game,
        prompt.defenderMinorOrTribeId,
      );
      final holdFlags = interventionHoldFlags(
        game: widget.game,
        interveningGpId: prompt.interveningGpId,
        defenderMinorOrTribeId: prompt.defenderMinorOrTribeId,
      );
      final TextStyle? holdReasonStyle =
          Theme.of(context).textTheme.bodySmall?.copyWith(
                color: EditorialMonoclePalette.muted,
              );
      return buildInterventionScrimmedShell(
        context: context,
        bodyChildren: [
          SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.game_intervention_resolutionProgress(
                      interventionPromptIndex + 1,
                      widget.prompts.length,
                    ),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: CtSpacing.ml),
                  Text(
                    l10n.game_intervention_choiceSituation(
                      aggressorName,
                      defenderName,
                    ),
                    key: const ValueKey<String>(kInterventionChoiceSituationKey),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (!holdFlags.isEmpty) ...[
                    const SizedBox(height: CtSpacing.s),
                    Text(
                      _holdReasonText(l10n, holdFlags),
                      key: const ValueKey<String>(kInterventionHoldReasonKey),
                      style: holdReasonStyle,
                    ),
                  ],
                  const SizedBox(height: CtSpacing.l),
                  InterventionChoiceButtons(
                    onPick: pickInterventionChoice,
                    interveneEffect: l10n.game_intervention_effectIntervene(
                      aggressorName,
                      defenderName,
                    ),
                    doNothingEffect: l10n.game_intervention_effectDoNothing(
                      aggressorName,
                      defenderName,
                    ),
                    protestEffect: l10n.game_intervention_effectProtest(
                      aggressorName,
                      defenderName,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return widget.child;
  }

  String _holdReasonText(AppLocalizations l10n, InterventionHoldFlags flags) {
    if (flags.hasEmbassy && flags.hasPurchasedLand) {
      return l10n.game_intervention_holdReasonEmbassyAndPurchasedLand;
    }
    if (flags.hasEmbassy) {
      return l10n.game_intervention_holdReasonEmbassy;
    }
    return l10n.game_intervention_holdReasonPurchasedLand;
  }
}
