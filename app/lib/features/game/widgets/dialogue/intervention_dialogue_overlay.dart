import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'intervention_dialogue_overlay_state.dart';

export 'intervention_dialogue_overlay_flow.dart'
    show interventionFactionDisplayName, reactionNodeForInterventionChoice;
export 'intervention_dialogue_overlay_shell.dart'
    show
        kInterventionOverlayBrassDividerKey,
        kInterventionOverlayTitleKey;
export 'intervention_dialogue_overlay_state.dart';

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
      InterventionDialogueOverlayState();
}
