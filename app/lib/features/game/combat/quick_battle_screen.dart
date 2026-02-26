import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'quick_battle_action_selector.dart';
import 'quick_battle_deployment_view.dart';

/// Quick Battle flow: deployment → rounds → result. SPEC/game/quick-battle.md.
/// Uses default actions (Volley Fire) when run in headless/AI mode.
class QuickBattleScreen extends StatefulWidget {
  const QuickBattleScreen({
    super.key,
    required this.input,
    required this.onComplete,
    this.interactive = false,
  });

  final QuickBattleInput input;
  final ValueChanged<QuickBattleResult> onComplete;
  final bool interactive;

  @override
  State<QuickBattleScreen> createState() => _QuickBattleScreenState();
}

class _QuickBattleScreenState extends State<QuickBattleScreen> {
  final int _round = 1;
  QuickBattleResult? _result;

  @override
  void initState() {
    super.initState();
    if (!widget.interactive) {
      _runWithDefaults();
    }
  }

  void _runWithDefaults() {
    final result = resolveQuickBattle(widget.input);
    setState(() => _result = result);
  }

  void _onActionSelected(QuickBattleAction action) {
    // For interactive mode, collect actions per round and run at end.
    // Simplified: run with single Volley Fire when user clicks.
    final result = resolveQuickBattle(
      widget.input,
      roundActions: [
        QuickBattleRoundActions(actions: [action]),
        QuickBattleRoundActions(actions: [QuickBattleAction.volleyFire]),
        QuickBattleRoundActions(actions: [QuickBattleAction.volleyFire]),
      ],
    );
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _ResultView(result: _result!, onDismiss: () {
        widget.onComplete(_result!);
      });
    }
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Quick Battle — Round $_round / ${widget.input.maxRounds}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: QuickBattleDeploymentView(
                    attackerDeployment: widget.input.attackerDeployment,
                    defenderDeployment: widget.input.defenderDeployment,
                    attackerName: widget.input.attackerFactionId,
                    defenderName: widget.input.defenderFactionId,
                  ),
                ),
              ),
              if (widget.interactive) ...[
                const SizedBox(height: 12),
                QuickBattleActionSelector(
                  cpRemaining: 3,
                  onActionSelected: _onActionSelected,
                ),
              ] else ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _runWithDefaults,
                  child: const Text('Resolve (Auto)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.onDismiss});

  final QuickBattleResult result;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final winnerText = switch (result.winner) {
      QuickBattleWinner.attacker => 'Attacker wins',
      QuickBattleWinner.defender => 'Defender holds',
      QuickBattleWinner.mutualExhaustion => 'Mutual exhaustion',
    };
    return AlertDialog(
      title: Text('Battle Result: $winnerText'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.provinceFlips)
            const Text('Province captured.', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Attacker casualties: ${result.attackerCasualties.length}'),
          Text('Defender casualties: ${result.defenderCasualties.length}'),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: onDismiss,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
