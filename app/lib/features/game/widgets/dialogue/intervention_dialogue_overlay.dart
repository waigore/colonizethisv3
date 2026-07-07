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

import '../../../../../l10n/l10n.dart';
import '../../../../../widgets/ct_brass_divider.dart';
import '../../../../../widgets/ct_full_screen_dialogue_shell.dart';
import '../../../../../widgets/ct_loading_indicator.dart';
import '../../../../../widgets/ct_nine_patch_button.dart';
import '../../../../../widgets/ct_spacing.dart';
import 'ct_dialogue_line_choice_body.dart';
import 'ct_dialogue_view.dart';
import 'intervention_choice_buttons.dart';

part 'intervention_dialogue_overlay_flow.dart';

/// Factory kept on the overlay host library so `repo.dialogue_blocking_combined_step`
/// sees `CtDialogueView(` and `CtDialogueLineChoiceBody(` in the same file after
/// the flow mixin was split into a `part` (Refs #3878).
CtDialogueView _createInterventionDialogueView(CtLogger log) =>
    CtDialogueView(logger: log);

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

class _InterventionDialogueOverlayState extends State<InterventionDialogueOverlay>
    with _InterventionDialogueOverlayFlow {
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
      return _buildScrimmedShell(
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
      return _buildScrimmedShell(
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
      return _buildScrimmedShell(
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
      return _buildScrimmedShell(
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

  /// Wrap the per-phase body in the dark editorial-monocle scrim +
  /// [CtFullScreenDialogueShell] with the canonical "Pending Intervention"
  /// title + [CtBrassDivider] header rendered on every phase (#2867 R1 / R2 /
  /// R26b; SPEC `SPEC/ui/screens/pending-intervention-overlay.md` § Dark
  /// editorial-monocle chrome). The scrim + framed shell scaffold lives in
  /// [CtFullScreenDialogueShell] (issue #2914 S2) so this method only owns
  /// the per-overlay title / divider composition.
  Widget _buildScrimmedShell({
    required BuildContext context,
    required List<Widget> bodyChildren,
    EdgeInsetsGeometry bodyPadding = const EdgeInsets.all(CtSpacing.xl),
  }) {
    final l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle titleStyle = _overlayTitleStyle(theme);
    return CtFullScreenDialogueShell(
      backdrop: widget.child,
      maxWidth: _kInterventionShellMaxWidth,
      padding: bodyPadding,
      body: Column(
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
