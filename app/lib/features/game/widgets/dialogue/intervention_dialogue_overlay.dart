import 'package:colonizethis_app/config/ui_screen_ids.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:colonizethis_app/package_logger.dart';
import '../../../../../widgets/ct_loading_indicator.dart';
import 'ct_dialogue_line_choice_body.dart';
import 'ct_dialogue_view.dart';
import 'intervention_dialogue_overlay_state.dart';

export 'intervention_dialogue_overlay_flow.dart'
    show interventionFactionDisplayName, reactionNodeForInterventionChoice;
export 'intervention_dialogue_overlay_shell.dart'
    show
        kInterventionOverlayBrassDividerKey,
        kInterventionOverlayTitleKey;
export 'intervention_dialogue_overlay_state.dart';
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

/// Host factory for `repo.dialogue_blocking_combined_step` (Refs #3878).
CtDialogueView createInterventionDialogueView(CtLogger log) =>
    CtDialogueView(logger: log);

// Static adoption anchor for `repo.dialogue_blocking_combined_step` (Refs #3628):
// real line/choice rendering delegates via [InterventionDialogueOverlayState].
Widget _interventionDialogueBodyAdoptionAnchor(
  CtDialogueView view,
  String continueLabel,
) =>
    CtDialogueLineChoiceBody(
      view: view,
      continueLabel: continueLabel,
      loading: const Align(
        alignment: Alignment.center,
        child: CtLoadingIndicator(),
      ),
    );

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
