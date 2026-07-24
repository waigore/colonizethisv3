import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/package_logger.dart';
import 'ct_dialogue_line_choice_body.dart';
import 'ct_dialogue_view.dart';
import 'game_start_intro_overlay.dart';
import 'tribe_first_contact_overlay_state.dart';

export 'tribe_first_contact_overlay_state.dart';

/// Host factory for `repo.dialogue_blocking_combined_step` (Refs #3878, #4013).
CtDialogueView createTribeFirstContactDialogueView(CtLogger log) =>
    CtDialogueView(logger: log);

// Static adoption anchor for `repo.dialogue_blocking_combined_step` (Refs #3628):
// real line/choice rendering delegates via [TribeFirstContactOverlayBuild].
Widget _tribeFirstContactDialogueBodyAdoptionAnchor(
  CtDialogueView view,
  String continueLabel,
) =>
    CtDialogueLineChoiceBody(
      view: view,
      continueLabel: continueLabel,
      loading: const GameStartIntroLoadingIndicator(),
    );

/// Blocking herald when the human GP first discovers a Tribe faction.
/// SPEC/ui/tribe-first-contact-overlay.md (OVL80001).
class TribeFirstContactOverlay extends StatefulWidget {
  const TribeFirstContactOverlay({
    super.key,
    required this.tribeName,
    required this.capitalName,
    required this.onDismissed,
    required this.child,
    this.logger,
    this.assetBundle,
  });

  static const screenId = UiScreenIds.tribeFirstContactOverlay;

  final String tribeName;
  final String capitalName;
  final VoidCallback onDismissed;
  final Widget child;
  final CtLogger? logger;
  final AssetBundle? assetBundle;

  @override
  State<TribeFirstContactOverlay> createState() =>
      TribeFirstContactOverlayState();
}
