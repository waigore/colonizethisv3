import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../../widgets/ct_brass_divider.dart';
import '../../../../../widgets/ct_full_screen_dialogue_shell.dart';
import '../../../../../widgets/ct_loading_indicator.dart';
import '../../../../../widgets/ct_nine_patch_button.dart';
import '../../../../../widgets/ct_spacing.dart';
import 'ct_dialogue_line_choice_body.dart';
import 'ct_dialogue_view.dart';

part 'game_start_intro_overlay_flow.dart';
part 'game_start_intro_overlay_build.dart';

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
  State<GameStartIntroOverlay> createState() => _GameStartIntroOverlayState();
}

class _GameStartIntroOverlayState extends State<GameStartIntroOverlay> {
  CtDialogueView? _view;
  DialogueRunner? _runner;
  Object? _loadError;
  bool _dialogueFinished = false;
  bool _loggedFirstLine = false;

  @override
  void initState() {
    super.initState();
    loadAndRunIntro();
  }

  @override
  Widget build(BuildContext context) => buildIntroOverlay(context);
}
