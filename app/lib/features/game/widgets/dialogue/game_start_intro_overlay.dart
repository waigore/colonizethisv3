import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:colonizethis_app/package_logger.dart';
import '../../../../../widgets/ct_loading_indicator.dart';
import 'ct_dialogue_line_choice_body.dart';
import 'ct_dialogue_view.dart';
import 'game_start_intro_overlay_state.dart';

export 'game_start_intro_overlay_state.dart';

/// Host factory for `repo.dialogue_blocking_combined_step` (Refs #3878, #4013).
CtDialogueView createGameStartIntroDialogueView(CtLogger log) =>
    CtDialogueView(logger: log);

// Static adoption anchor for `repo.dialogue_blocking_combined_step` (Refs #3628):
// real line/choice rendering delegates via [GameStartIntroOverlayBuild].
Widget _gameStartIntroDialogueBodyAdoptionAnchor(
  CtDialogueView view,
  String continueLabel,
) =>
    CtDialogueLineChoiceBody(view: view, continueLabel: continueLabel);

/// Spinner while intro dialogue lines are not yet available.
///
/// Matches the game-initializing progress dialog contract
/// (`NewGameSetupProgressView` / SHEL30001 R32): 48 logical px ring with
/// `--accent` stroke (`EditorialMonoclePalette.accent`). Refs #2867 R28.
class GameStartIntroLoadingIndicator extends StatelessWidget {
  const GameStartIntroLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return CtLoadingIndicator(
      size: 48,
      strokeWidth: 2,
      color: EditorialMonoclePalette.accent,
      center: false,
    );
  }
}

/// Modal overlay that shows the game-start intro dialogue (archaic language) and
/// blocks until the player dismisses it. SPEC/ai/dialogue-management.md § First dialogue emission point.
class GameStartIntroOverlay extends StatefulWidget {
  const GameStartIntroOverlay({
    super.key,
    required this.onDismissed,
    required this.child,
    this.logger,

    /// When set (e.g. in tests), used to load the Yarn asset instead of [rootBundle].
    this.assetBundle,
  });

  /// SPEC/ui/game-start-intro-overlay.md — [UiScreenIds.gameStartIntroOverlay].
  static const screenId = UiScreenIds.gameStartIntroOverlay;

  final VoidCallback onDismissed;
  final Widget child;
  final CtLogger? logger;
  final AssetBundle? assetBundle;

  @override
  State<GameStartIntroOverlay> createState() => GameStartIntroOverlayState();
}
