import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:colonizethis_app/package_logger.dart';
import 'ct_dialogue_line_choice_body.dart';
import 'ct_dialogue_view.dart';
import 'overture_dialogue_overlay_state.dart';

export 'overture_dialogue_overlay_state.dart';

/// Host factory for `repo.dialogue_blocking_combined_step` (Refs #3878).
CtDialogueView createOvertureDialogueView(CtLogger log) =>
    CtDialogueView(logger: log);

// Static adoption anchor for `repo.dialogue_blocking_combined_step` (Refs #3628):
// real line/choice rendering delegates via [OvertureDialogueOverlayState].
Widget _overtureDialogueBodyAdoptionAnchor(
  CtDialogueView view,
  String continueLabel,
) =>
    CtDialogueLineChoiceBody(view: view, continueLabel: continueLabel);

/// Modal overture dialogue: Jenny-driven intro line then Accept/Reject per offer
/// and Submit. SPEC/ui/dialogue-presentation.md, SPEC/ai/dialogue-content-and-yarn.md.
class OvertureDialogueOverlay extends StatefulWidget {
  const OvertureDialogueOverlay({
    super.key,
    required this.game,
    required this.pendingOvertures,
    required this.onDecisions,
    required this.child,
    this.logger,

    /// When true, skip Jenny intro and show list immediately. For tests only.
    this.skipIntroForTest = false,
    this.assetBundle,
  });

  /// SPEC/ui/overture-dialogue-overlay.md — [UiScreenIds.overtureDialogueOverlay].
  static const screenId = UiScreenIds.overtureDialogueOverlay;

  final Game game;
  final List<OvertureOffer> pendingOvertures;
  final void Function(List<OvertureDecision> decisions) onDecisions;
  final Widget child;
  final CtLogger? logger;
  final bool skipIntroForTest;

  /// Optional asset bundle override for loading the overture Yarn asset.
  /// Defaults to [rootBundle]; tests inject a deterministic in-memory bundle
  /// (mirrors `InterventionDialogueOverlay`).
  final AssetBundle? assetBundle;

  @override
  State<OvertureDialogueOverlay> createState() =>
      OvertureDialogueOverlayState();
}
