import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import '../../../../../widgets/ct_full_screen_dialogue_shell.dart';
import '../../../../../widgets/ct_loading_indicator.dart';
import '../../../../../widgets/ct_nine_patch_button.dart';
import '../../../../../widgets/ct_spacing.dart';
import '../../../../../widgets/ct_toggle_switch.dart';
import 'ct_dialogue_line_choice_body.dart';
import 'ct_dialogue_view.dart';
import 'yarn_dialogue_bootstrap.dart';

part 'overture_dialogue_overlay_flow.dart';
part 'overture_dialogue_overlay_offer_row.dart';
part 'overture_dialogue_overlay_phase_two.dart';
part 'overture_dialogue_overlay_build.dart';

/// Factory kept on the overlay host library so `repo.dialogue_blocking_combined_step`
/// sees `CtDialogueView(` and `CtDialogueLineChoiceBody(` in the same file after
/// the flow mixin was split into a `part` (Refs #3878).
CtDialogueView _createOvertureDialogueView(CtLogger log) =>
    CtDialogueView(logger: log);

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
      _OvertureDialogueOverlayState();
}

class _OvertureDialogueOverlayState extends State<OvertureDialogueOverlay>
    with _OvertureDialogueOverlayFlow {
  @override
  bool overtureIntroDone = false;
  @override
  CtDialogueView? overtureView;
  @override
  Object? overtureLoadError;

  /// Per-offer decisions; `null` means the player has not yet tapped Accept
  /// or Reject on that row. The Submit button stays disabled until every
  /// entry is non-null (issue #2867 R23 / AC4).
  late List<bool?> _accepted;

  @override
  void initState() {
    super.initState();
    _accepted = List<bool?>.filled(widget.pendingOvertures.length, null);
    if (widget.skipIntroForTest) {
      overtureIntroDone = true;
    } else {
      loadAndRunOvertureIntro();
    }
  }

  void _updateOvertureDecision(int index, bool? next) {
    setState(() => _accepted[index] = next);
  }

  @override
  Widget build(BuildContext context) => buildOvertureDialogueOverlay(context);
}
