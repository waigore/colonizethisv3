// Military victory overlay host.
//
// De-parted wave-9 cluster (Refs #4117): explicit-import libraries replace the
// former 3-part library. Public surface: [VictoryOverlay], [VictoryPanel].

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';

import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_full_screen_dialogue_shell.dart';
import 'victory_overlay_panel.dart';

export 'victory_overlay_panel.dart' show VictoryPanel;

/// Stateful overlay so "View final state" can hide the panel without a route (SPEC/game/victory.md).
///
/// Visual contract: SPEC/ui/victory-overlay.md — dark `--dialog-scrim` wash,
/// centered brass-bordered [VictoryPanel] with laurel decoration, brass
/// divider, and asymmetric corner brackets.
class VictoryOverlay extends StatefulWidget {
  const VictoryOverlay({
    required this.game,
    required this.victory,
    required this.bus,
    super.key,
  });

  /// SPEC/ui/victory-overlay.md — [UiScreenIds.victoryOverlay].
  static const screenId = UiScreenIds.victoryOverlay;

  final ct_models.Game game;
  final ct_models.VictoryState victory;
  final ct_models.AppEventBus bus;

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Positioned.fill(
      child: CtFullScreenDialogueShell(
        backdrop: const SizedBox.shrink(),
        wrapBodyInDialogShell: false,
        padding: EdgeInsets.zero,
        body: VictoryPanel(
          game: widget.game,
          victory: widget.victory,
          bus: widget.bus,
          onViewFinalState: () => setState(() => _dismissed = true),
        ),
      ),
    );
  }
}
