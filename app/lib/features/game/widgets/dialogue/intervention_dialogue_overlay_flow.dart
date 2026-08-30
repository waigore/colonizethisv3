// Yarn flow orchestration for [InterventionDialogueOverlay].
// Split from `intervention_dialogue_overlay.dart` to keep the overlay host
// under the repo file-size target (Refs #3878).

import 'dart:async';

import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/core/utils/faction_display_name.dart';
import 'package:colonizethis_app/package_logger.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jenny/jenny.dart';

import 'ct_dialogue_view.dart';
import 'intervention_dialogue_overlay.dart';
import 'yarn_dialogue_bootstrap.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';

mixin InterventionDialogueOverlayFlow on State<InterventionDialogueOverlay> {
  YarnProject? get interventionProject;
  set interventionProject(YarnProject? value);
  DialogueRunner? get interventionRunner;
  set interventionRunner(DialogueRunner? value);
  CtDialogueView? get interventionView;
  set interventionView(CtDialogueView? value);
  Object? get interventionLoadError;
  set interventionLoadError(Object? value);
  bool get interventionYarnUiActive;
  set interventionYarnUiActive(bool value);
  bool get interventionAwaitingChoice;
  set interventionAwaitingChoice(bool value);
  Completer<InterventionChoice>? get interventionChoiceCompleter;
  set interventionChoiceCompleter(Completer<InterventionChoice>? value);
  List<InterventionDecision> get interventionDecisions;
  int get interventionPromptIndex;
  set interventionPromptIndex(int value);

  Future<void> runInterventionFlow() async {
    final log = widget.logger ?? packageLogger('dialogue');
    try {
      final bundle = widget.assetBundle ?? rootBundle;
      // Seed `$`-prefixed vars before parse (Jenny interpolate, Refs #3463).
      final session = await loadYarnDialogueSession(
        bundle: bundle,
        assetPath: kDialogueInterventionAsset,
        logger: log,
        createView: createInterventionDialogueView,
        beforeParse: (project) {
          project.variables.setVariable(r'$aggressorName', '');
          project.variables.setVariable(r'$defenderName', '');
          project.variables.setVariable(r'$interveningName', '');
        },
        requiredNodes: const [
          kInterventionIntroNode,
          kInterventionSituationNode,
          kInterventionReactInterveneNode,
          kInterventionReactNothingNode,
          kInterventionReactProtestNode,
        ],
      );
      final project = session.project;
      final view = session.view;
      final runner = session.runner;
      if (!mounted) return;
      setState(() {
        interventionProject = project;
        interventionRunner = runner;
        interventionView = view;
        view.onStateChanged = (line, choice) {
          if (mounted) setState(() {});
        };
      });

      if (widget.prompts.isEmpty) {
        widget.onDecisions(const []);
        return;
      }

      if (!widget.skipIntroForTest) {
        setState(() => interventionYarnUiActive = true);
        await runner.startDialogue(kInterventionIntroNode);
        if (!mounted) return;
      }

      for (var i = 0; i < widget.prompts.length; i++) {
        if (!mounted) return;
        interventionPromptIndex = i;
        final prompt = widget.prompts[i];
        setInterventionFactionVariables(project, prompt);
        setState(() => interventionYarnUiActive = true);
        await runner.startDialogue(kInterventionSituationNode);
        if (!mounted) return;

        final completer = Completer<InterventionChoice>();
        interventionChoiceCompleter = completer;
        setState(() {
          interventionYarnUiActive = false;
          interventionAwaitingChoice = true;
        });
        final choice = await completer.future;
        if (!mounted) return;
        setState(() => interventionAwaitingChoice = false);
        interventionChoiceCompleter = null;

        interventionDecisions.add(
          InterventionDecision(
            aggressorGpId: prompt.aggressorGpId,
            defenderMinorOrTribeId: prompt.defenderMinorOrTribeId,
            interveningGpId: prompt.interveningGpId,
            choice: choice,
          ),
        );

        project.variables.setVariable(
          r'$aggressorName',
          interventionFactionDisplayName(widget.game, prompt.aggressorGpId),
        );
        setState(() => interventionYarnUiActive = true);
        await runner.startDialogue(reactionNodeForInterventionChoice(choice));
        if (!mounted) return;
        setState(() => interventionYarnUiActive = false);
      }

      if (!mounted) return;
      widget.onDecisions(
        List<InterventionDecision>.from(interventionDecisions),
      );
    } catch (e, st) {
      log.e('ui:dialogue: intervention flow failed', error: e, stackTrace: st);
      if (mounted) setState(() => interventionLoadError = e);
    }
  }

  void setInterventionFactionVariables(
    YarnProject project,
    InterventionPrompt prompt,
  ) {
    // Jenny stores Yarn variables under their `$`-prefixed name; the asset
    // interpolates `{$aggressorName}` etc. Binding without the prefix raised a
    // Jenny `NameError` at runtime (#3463).
    project.variables.setVariable(
      r'$aggressorName',
      interventionFactionDisplayName(widget.game, prompt.aggressorGpId),
    );
    project.variables.setVariable(
      r'$defenderName',
      interventionFactionDisplayName(
        widget.game,
        prompt.defenderMinorOrTribeId,
      ),
    );
    project.variables.setVariable(
      r'$interveningName',
      interventionFactionDisplayName(widget.game, prompt.interveningGpId),
    );
  }

  void pickInterventionChoice(InterventionChoice choice) {
    final c = interventionChoiceCompleter;
    if (c != null && !c.isCompleted) {
      c.complete(choice);
    }
  }

  void degradedSubmitInterventionDoNothing() {
    final out = <InterventionDecision>[];
    for (final p in widget.prompts) {
      out.add(
        InterventionDecision(
          aggressorGpId: p.aggressorGpId,
          defenderMinorOrTribeId: p.defenderMinorOrTribeId,
          interveningGpId: p.interveningGpId,
          choice: InterventionChoice.doNothing,
        ),
      );
    }
    widget.onDecisions(out);
  }
}

String reactionNodeForInterventionChoice(InterventionChoice choice) {
  switch (choice) {
    case InterventionChoice.intervene:
      return kInterventionReactInterveneNode;
    case InterventionChoice.doNothing:
      return kInterventionReactNothingNode;
    case InterventionChoice.protest:
      return kInterventionReactProtestNode;
  }
}

String interventionFactionDisplayName(Game game, String factionId) =>
    displayNameForFaction(game, factionId);

const String kInterventionIntroNode = 'DialoguePoint/intervention_intro';
const String kInterventionSituationNode =
    'DialoguePoint/intervention_situation';
const String kInterventionReactInterveneNode =
    'DialoguePoint/intervention_reaction_intervene';
const String kInterventionReactNothingNode =
    'DialoguePoint/intervention_reaction_do_nothing';
const String kInterventionReactProtestNode =
    'DialoguePoint/intervention_reaction_protest';
