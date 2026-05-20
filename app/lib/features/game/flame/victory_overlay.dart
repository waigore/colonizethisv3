import 'package:flutter/material.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../l10n/l10n.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_panel.dart';

/// Stateful overlay so "View final state" can hide the panel without a route (SPEC/game/victory.md).
class VictoryOverlay extends StatefulWidget {
  const VictoryOverlay({
    required this.game,
    required this.victory,
    required this.bus,
    super.key,
  });

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
      child: Container(
        color: Colors.black54,
        child: Center(
          child: VictoryPanel(
            game: widget.game,
            victory: widget.victory,
            bus: widget.bus,
            onViewFinalState: () => setState(() => _dismissed = true),
          ),
        ),
      ),
    );
  }
}

class VictoryPanel extends StatelessWidget {
  const VictoryPanel({
    required this.game,
    required this.victory,
    required this.bus,
    this.onViewFinalState,
    super.key,
  });

  final ct_models.Game game;
  final ct_models.VictoryState victory;
  final ct_models.AppEventBus bus;
  final VoidCallback? onViewFinalState;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final winner =
        game.playerById(victory.winnerPlayerId) ?? game.players.first;
    final victoryLabel = switch (victory.type) {
      ct_models.VictoryType.military => l10n.victory_military,
    };

    return Padding(
      padding: const EdgeInsets.all(24),
      child: CtPanel(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              victoryLabel,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.victory_winnerOnTurn(winner.displayName, victory.turnNumber),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CtNinePatchButton(
                  onPressed: () =>
                      bus.emit(const ct_models.NavigateToShellEvent()),
                  child: Text(l10n.victory_returnToMainMenu),
                ),
                const SizedBox(width: 12),
                CtNinePatchButton(
                  onPressed: () {
                    onViewFinalState?.call();
                  },
                  child: Text(l10n.victory_viewFinalState),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
