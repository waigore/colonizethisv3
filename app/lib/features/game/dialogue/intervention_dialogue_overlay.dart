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
      return _buildScrimmedShell(
        context: context,
        bodyChildren: [
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
        bodyPadding: const EdgeInsets.all(16),
      );
    }

    if (_project == null || _runner == null || _view == null) {
      return _buildScrimmedShell(
        context: context,
        bodyChildren: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Align(
              alignment: Alignment.center,
              child: CtLoadingIndicator(),
            ),
          ),
        ],
      );
    }

    if (_yarnUiActive) {
      final line = _view!.currentLine;
      final choice = _view!.currentChoice;
      return _buildScrimmedShell(
        context: context,
        bodyChildren: [
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
            const Align(
              alignment: Alignment.center,
              child: CtLoadingIndicator(),
            ),
        ],
      );
    } else if (_awaitingChoice) {
      final prompt = widget.prompts[_promptIndex];
      return _buildScrimmedShell(
        context: context,
        bodyChildren: [
          Text(
            l10n.game_intervention_resolutionProgress(
              _promptIndex + 1,
              widget.prompts.length,
            ),
            style: Theme.of(context).textTheme.titleSmall,
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
            style: Theme.of(context).textTheme.bodyMedium,
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
      );
    }

    return widget.child;
  }

  /// Wrap the per-phase body in the dark editorial-monocle scrim + `CtDialogShell`
  /// with the canonical "Pending Intervention" title + [CtBrassDivider] header
  /// rendered on every phase (#2867 R1 / R2 / R26b; SPEC
  /// `SPEC/ui/screens/pending-intervention-overlay.md` § Dark editorial-monocle
  /// chrome).
  Widget _buildScrimmedShell({
    required BuildContext context,
    required List<Widget> bodyChildren,
    EdgeInsetsGeometry bodyPadding = const EdgeInsets.all(20),
  }) {
    final l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle titleStyle = _overlayTitleStyle(theme);
    return Stack(
      children: [
        widget.child,
        Material(
          color: EditorialMonoclePalette.dialogScrim,
          child: Center(
            child: CtDialogShell(
              maxWidth: _kInterventionShellMaxWidth,
              child: Padding(
                padding: bodyPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.game_intervention_overlayTitle,
                      key: const ValueKey<String>(kInterventionOverlayTitleKey),
                      style: titleStyle,
                    ),
                    const SizedBox(height: _kTitleToDividerGap),
                    const CtBrassDivider(
                      key: ValueKey<String>(kInterventionOverlayBrassDividerKey),
                    ),
                    const SizedBox(height: _kDividerToBodyGap),
                    ...bodyChildren,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Canonical title style per #2867 R2: `--accent` text with a 0.05em
  /// letter-spacing computed from the resolved title `fontSize` so the
  /// spacing scales with theme `titleMedium` overrides.
  TextStyle _overlayTitleStyle(ThemeData theme) {
    final TextStyle base =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final double fontSize = base.fontSize ?? 16;
    return base.copyWith(
      color: EditorialMonoclePalette.accent,
      letterSpacing: fontSize * _kOverlayTitleLetterSpacingEm,
    );
  }
}

/// Stable key for the "Pending Intervention" title `Text` widget so widget
/// tests can pin the dark editorial-monocle chrome contract without matching
/// localized strings.
const String kInterventionOverlayTitleKey = 'interventionOverlayTitle';

/// Stable key for the [CtBrassDivider] beneath the title.
const String kInterventionOverlayBrassDividerKey =
    'interventionOverlayBrassDivider';

/// Maximum content width inside `CtDialogShell` for the intervention overlay.
/// Shared with the prior layout (520 dp).
const double _kInterventionShellMaxWidth = 520;

/// Vertical gap between the title and the [CtBrassDivider] (#2867 SPEC table).
const double _kTitleToDividerGap = 8;

/// Vertical gap between the [CtBrassDivider] and the per-phase body.
const double _kDividerToBodyGap = 12;

/// Canonical 0.05em letter-spacing factor for the overlay title (#2867 R2).
const double _kOverlayTitleLetterSpacingEm = 0.05;
