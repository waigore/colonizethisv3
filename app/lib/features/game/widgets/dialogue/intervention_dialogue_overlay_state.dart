import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
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
      return buildInterventionScrimmedShell(
        context: context,
        bodyChildren: [
          Text(
            l10n.game_intervention_resolutionProgress(
              interventionPromptIndex + 1,
              widget.prompts.length,
            ),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: CtSpacing.ml),
          Text(
            l10n.game_intervention_situation(
              interventionFactionDisplayName(widget.game, prompt.aggressorGpId),
              interventionFactionDisplayName(
                widget.game,
                prompt.defenderMinorOrTribeId,
              ),
              interventionFactionDisplayName(
                widget.game,
                prompt.interveningGpId,
              ),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: CtSpacing.l),
          InterventionChoiceButtons(onPick: pickInterventionChoice),
        ],
      );
    }

    return widget.child;
  }
}
