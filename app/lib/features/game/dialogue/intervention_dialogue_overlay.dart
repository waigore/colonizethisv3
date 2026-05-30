import 'dart:async';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/services.dart';
import 'package:jenny/jenny.dart';

import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_brass_divider.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_loading_indicator.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import 'ct_dialogue_view.dart';

/// Blocking intervention dialogue: Yarn intro, per-prompt situation + reaction, three choices.
/// SPEC/ui/screens/pending-intervention-overlay.md, SPEC/ai/dialogue-content-and-yarn.md.
class InterventionDialogueOverlay extends StatefulWidget {
  const InterventionDialogueOverlay({
    super.key,
    required this.game,
    required this.prompts,
    required this.onDecisions,
    required this.child,
    this.logger,
    this.skipIntroForTest = false,
    this.assetBundle,
  });

  /// SPEC/ui/screens/pending-intervention-overlay.md — [UiScreenIds.pendingInterventionOverlay].
  static const screenId = UiScreenIds.pendingInterventionOverlay;

  final Game game;
  final List<InterventionPrompt> prompts;
  final void Function(List<InterventionDecision> decisions) onDecisions;
  final Widget child;
  final CtLogger? logger;
  final bool skipIntroForTest;
  final AssetBundle? assetBundle;

  @override
  State<InterventionDialogueOverlay> createState() =>
      _InterventionDialogueOverlayState();
}

class _InterventionDialogueOverlayState
    extends State<InterventionDialogueOverlay> {
  static const String _kIntro = 'DialoguePoint/intervention_intro';
  static const String _kSituation = 'DialoguePoint/intervention_situation';
  static const String _kReactIntervene =
      'DialoguePoint/intervention_reaction_intervene';
  static const String _kReactNothing =
      'DialoguePoint/intervention_reaction_do_nothing';
  static const String _kReactProtest =
      'DialoguePoint/intervention_reaction_protest';

  YarnProject? _project;
  DialogueRunner? _runner;
  CtDialogueView? _view;
  Object? _loadError;
  bool _yarnUiActive = false;
  bool _awaitingChoice = false;
  Completer<InterventionChoice>? _choiceCompleter;
  final List<InterventionDecision> _decisions = [];
  int _promptIndex = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_runFlow());
  }

  Future<void> _runFlow() async {
    final log = widget.logger ?? packageLogger('dialogue');
    try {
      final bundle = widget.assetBundle ?? rootBundle;
      final text = await bundle.loadString(kDialogueInterventionAsset);
      final project = YarnProject()..parse(text);
      for (final node in [
        _kIntro,
        _kSituation,
        _kReactIntervene,
        _kReactNothing,
        _kReactProtest,
      ]) {
        if (!project.nodes.containsKey(node)) {
          throw StateError(
            'Intervention node "$node" missing in $kDialogueInterventionAsset',
          );
        }
      }
      final view = CtDialogueView(logger: log);
      final runner = DialogueRunner(
        yarnProject: project,
        dialogueViews: [view],
      );
      if (!mounted) return;
      setState(() {
        _project = project;
        _runner = runner;
        _view = view;
        view.onStateChanged = (line, choice) {
          if (mounted) setState(() {});
        };
      });

      if (widget.prompts.isEmpty) {
        widget.onDecisions(const []);
        return;
      }

      if (!widget.skipIntroForTest) {
        setState(() => _yarnUiActive = true);
        await runner.startDialogue(_kIntro);
        if (!mounted) return;
      }

      for (var i = 0; i < widget.prompts.length; i++) {
        if (!mounted) return;
        _promptIndex = i;
        final prompt = widget.prompts[i];
        _setFactionVariables(project, prompt);
        setState(() => _yarnUiActive = true);
        await runner.startDialogue(_kSituation);
        if (!mounted) return;

        final completer = Completer<InterventionChoice>();
        _choiceCompleter = completer;
        setState(() {
          _yarnUiActive = false;
          _awaitingChoice = true;
        });
        final choice = await completer.future;
        if (!mounted) return;
        setState(() => _awaitingChoice = false);
        _choiceCompleter = null;

        _decisions.add(
          InterventionDecision(
            aggressorGpId: prompt.aggressorGpId,
            defenderMinorOrTribeId: prompt.defenderMinorOrTribeId,
            interveningGpId: prompt.interveningGpId,
            choice: choice,
          ),
        );

        project.variables.setVariable(
          'aggressorName',
          _factionDisplayName(widget.game, prompt.aggressorGpId),
        );
        setState(() => _yarnUiActive = true);
        await runner.startDialogue(_reactionNodeFor(choice));
        if (!mounted) return;
        setState(() => _yarnUiActive = false);
      }

      if (!mounted) return;
      widget.onDecisions(List<InterventionDecision>.from(_decisions));
    } catch (e, st) {
      log.e('ui:dialogue: intervention flow failed', error: e, stackTrace: st);
      if (mounted) setState(() => _loadError = e);
    }
  }

  void _setFactionVariables(YarnProject project, InterventionPrompt prompt) {
    project.variables.setVariable(
      'aggressorName',
      _factionDisplayName(widget.game, prompt.aggressorGpId),
    );
    project.variables.setVariable(
      'defenderName',
      _factionDisplayName(widget.game, prompt.defenderMinorOrTribeId),
    );
    project.variables.setVariable(
      'interveningName',
      _factionDisplayName(widget.game, prompt.interveningGpId),
    );
  }

  static String _reactionNodeFor(InterventionChoice choice) {
    switch (choice) {
      case InterventionChoice.intervene:
        return _kReactIntervene;
      case InterventionChoice.doNothing:
        return _kReactNothing;
      case InterventionChoice.protest:
        return _kReactProtest;
    }
  }

  static String _factionDisplayName(Game game, String factionId) {
    for (final p in game.players) {
      if (p.id == factionId) return p.displayName;
    }
    for (final m in game.minorNations) {
      if (m.id == factionId) return m.displayName ?? m.id;
    }
    for (final t in game.tribes) {
      if (t.id == factionId) return t.displayName ?? t.id;
    }
    return factionId;
  }

  void _pick(InterventionChoice choice) {
    final c = _choiceCompleter;
    if (c != null && !c.isCompleted) {
      c.complete(choice);
    }
  }

  void _degradedSubmitDoNothing() {
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

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    if (_loadError != null) {
      return Stack(
        children: [
          widget.child,
          Material(
            color: EditorialMonoclePalette.dialogScrim,
            child: Center(
              child: CtDialogShell(
                maxWidth: 520,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.game_intervention_loadError(_loadError.toString()),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.game_intervention_degradedHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: CtNinePatchButton(
                          onPressed: _degradedSubmitDoNothing,
                          child: Text(l10n.game_intervention_continue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_project == null || _runner == null || _view == null) {
      return Stack(
        children: [
          widget.child,
          Material(
            color: EditorialMonoclePalette.dialogScrim,
            child: Center(
              child: CtDialogShell(
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: CtLoadingIndicator(),
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget? dialoguePanel;
    if (_yarnUiActive) {
      final line = _view!.currentLine;
      final choice = _view!.currentChoice;
      dialoguePanel = CtDialogShell(
        maxWidth: 520,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (line != null) ...[
                Text(line.text, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: CtNinePatchButton(
                    onPressed: () => _view!.advanceLine(),
                    child: Text(l10n.game_intervention_continue),
                  ),
                ),
              ] else if (choice != null) ...[
                ...choice.options.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CtNinePatchButton(
                      onPressed: () => _view!.selectOption(entry.key),
                      child: Text(entry.value.text),
                    ),
                  ),
                ),
              ] else
                const CtLoadingIndicator(),
            ],
          ),
        ),
      );
    } else if (_awaitingChoice) {
      final prompt = widget.prompts[_promptIndex];
      final ThemeData theme = Theme.of(context);
      final TextStyle baseTitle =
          theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
      final TextStyle titleStyle = baseTitle.copyWith(
        color: EditorialMonoclePalette.accent,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * (baseTitle.fontSize ?? 16),
      );
      dialoguePanel = CtDialogShell(
        maxWidth: 520,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.game_intervention_title,
                style: titleStyle,
              ),
              const SizedBox(height: 12),
              const CtBrassDivider(),
              const SizedBox(height: 12),
              Text(
                l10n.game_intervention_resolutionProgress(
                  _promptIndex + 1,
                  widget.prompts.length,
                ),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.game_intervention_situation(
                  _factionDisplayName(widget.game, prompt.aggressorGpId),
                  _factionDisplayName(
                    widget.game,
                    prompt.defenderMinorOrTribeId,
                  ),
                  _factionDisplayName(widget.game, prompt.interveningGpId),
                ),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              CtNinePatchButton(
                onPressed: () => _pick(InterventionChoice.intervene),
                child: Text(l10n.game_intervention_intervene),
              ),
              const SizedBox(height: 8),
              CtNinePatchButton(
                onPressed: () => _pick(InterventionChoice.doNothing),
                child: Text(l10n.game_intervention_doNothing),
              ),
              const SizedBox(height: 8),
              CtNinePatchButton(
                onPressed: () => _pick(InterventionChoice.protest),
                child: Text(l10n.game_intervention_protest),
              ),
            ],
          ),
        ),
      );
    }

    if (dialoguePanel == null) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Material(
          color: EditorialMonoclePalette.dialogScrim,
          child: Center(child: dialoguePanel),
        ),
      ],
    );
  }
}
