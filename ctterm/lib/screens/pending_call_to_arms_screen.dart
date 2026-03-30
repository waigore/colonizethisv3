// Pending call to arms: join or refuse when an ally is declared upon. SPEC/game/diplomacy.md.

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final _log = tuiLogger();

/// Screen when turn resolution blocks on human ally call to arms.
class PendingCallToArmsScreen extends StatefulComponent {
  const PendingCallToArmsScreen({
    super.key,
    required this.game,
    required this.pending,
    required this.onDecisions,
  });

  final Game game;
  final List<CallToArmsPending> pending;
  final void Function(List<CallToArmsDecision> decisions) onDecisions;

  @override
  State<PendingCallToArmsScreen> createState() =>
      _PendingCallToArmsScreenState();
}

class _PendingCallToArmsScreenState extends State<PendingCallToArmsScreen> {
  int _selectedIndex = 0;
  late List<bool> _join;

  @override
  void initState() {
    super.initState();
    _join = List.filled(component.pending.length, true);
  }

  String _gpName(String gpId) {
    final p = component.game.players.where((e) => e.id == gpId).firstOrNull;
    return p?.displayName ?? gpId;
  }

  @override
  Component build(BuildContext context) {
    final items = component.pending;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(1),
        child: Text('No pending call to arms.'),
      );
    }
    return Focusable(
      focused: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Call to arms', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('An ally is at war. Join (J) or refuse (R) each line; Enter submits.'),
            const SizedBox(height: 1),
            ...List.generate(items.length, (i) {
              final c = items[i];
              final isSelected = i == _selectedIndex;
              final choice = _join[i] ? 'Join' : 'Refuse';
              final prefix = isSelected ? '> ' : '  ';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Text(
                  '$prefix${_gpName(c.defenderGpId)} attacked by ${_gpName(c.aggressorGpId)}. $choice',
                ),
              );
            }),
            const SizedBox(height: 2),
            const Text('[J] Join  [R] Refuse  [Up/Down] Select  [Enter] Submit'),
          ],
        ),
      ),
    );
  }

  // ignore: strict_top_level_inference
  bool _handleKeyEvent(event) {
    final key = event.logicalKey;
    final c = event.character?.toLowerCase();
    final n = component.pending.length;
    if (n == 0) return false;

    if (c == 'j') {
      setState(() => _join[_selectedIndex] = true);
      return true;
    }
    if (c == 'r') {
      setState(() => _join[_selectedIndex] = false);
      return true;
    }
    if (key == LogicalKey.arrowUp || c == 'w') {
      setState(() {
        if (_selectedIndex > 0) _selectedIndex--;
      });
      return true;
    }
    if (key == LogicalKey.arrowDown || c == 's') {
      setState(() {
        if (_selectedIndex < n - 1) _selectedIndex++;
      });
      return true;
    }
    if (key == LogicalKey.enter) {
      final decisions = <CallToArmsDecision>[];
      for (var i = 0; i < component.pending.length; i++) {
        final p = component.pending[i];
        decisions.add(
          CallToArmsDecision(
            allyGpId: p.allyGpId,
            defenderGpId: p.defenderGpId,
            aggressorGpId: p.aggressorGpId,
            accepted: _join[i],
          ),
        );
      }
      _log.d('submitting ${decisions.length} decision(s)');
      component.onDecisions(decisions);
      return true;
    }
    return false;
  }
}
