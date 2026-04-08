// Pending overtures: accept/reject diplomatic offers during turn resolution.
// SPEC/program/turn-resolution-phases.md, SPEC/game/diplomacy.md.

import 'package:ctterm/package_logger.dart';
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final _log = packageLogger();

/// Screen shown when turn resolution blocks on the human player accepting or
/// rejecting diplomatic overtures from other players.
class PendingOverturesScreen extends StatefulComponent {
  const PendingOverturesScreen({
    super.key,
    required this.game,
    required this.pendingOvertures,
    required this.onDecisions,
  });

  final Game game;
  final List<OvertureOffer> pendingOvertures;
  final void Function(List<OvertureDecision> decisions) onDecisions;

  @override
  State<PendingOverturesScreen> createState() => _PendingOverturesScreenState();
}

class _PendingOverturesScreenState extends State<PendingOverturesScreen> {
  /// Selected row index (which offer to change with A/R).
  int _selectedIndex = 0;
  /// Per-offer: true = accept, false = reject.
  late List<bool> _accepted;

  @override
  void initState() {
    super.initState();
    _accepted = List.filled(component.pendingOvertures.length, true);
  }

  String _offererDisplayName(String offererGpId) {
    final p = component.game.players.where((e) => e.id == offererGpId).firstOrNull;
    return p?.displayName ?? offererGpId;
  }

  static String _stageLabel(OvertureStage stage) {
    switch (stage) {
      case OvertureStage.tradeConsulate:
        return 'Trade Consulate';
      case OvertureStage.embassy:
        return 'Embassy';
      case OvertureStage.nap:
        return 'Non-Aggression Pact';
      case OvertureStage.joinEmpire:
        return 'Join Empire';
      case OvertureStage.none:
        return 'None';
    }
  }

  @override
  Component build(BuildContext context) {
    final offers = component.pendingOvertures;
    if (offers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(1),
        child: Text('No pending overtures.'),
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
            const Text('Diplomatic overtures', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Other players have offered you diplomatic agreements. Accept or reject each.'),
            const SizedBox(height: 1),
            ...List.generate(offers.length, (i) {
              final offer = offers[i];
              final isSelected = i == _selectedIndex;
              final choice = _accepted[i] ? 'Accept' : 'Reject';
              final prefix = isSelected ? '> ' : '  ';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Text(
                  '$prefix${_offererDisplayName(offer.offererGpId)} offers ${_stageLabel(offer.stage)}. Current: $choice',
                ),
              );
            }),
            const SizedBox(height: 2),
            const Text('[A] Accept  [R] Reject  [Up/Down] Select  [Enter] Submit'),
          ],
        ),
      ),
    );
  }

  // ignore: strict_top_level_inference
  bool _handleKeyEvent(event) {
    final key = event.logicalKey;
    final c = event.character?.toLowerCase();
    final n = component.pendingOvertures.length;

    if (n == 0) return false;

    if (c == 'a') {
      setState(() => _accepted[_selectedIndex] = true);
      return true;
    }
    if (c == 'r') {
      setState(() => _accepted[_selectedIndex] = false);
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
      final decisions = <OvertureDecision>[];
      for (var i = 0; i < component.pendingOvertures.length; i++) {
        final offer = component.pendingOvertures[i];
        decisions.add(OvertureDecision(
          offererGpId: offer.offererGpId,
          targetFactionId: offer.targetFactionId,
          stage: offer.stage,
          accepted: _accepted[i],
        ));
      }
      _log.d('submitting ${decisions.length} decision(s)');
      component.onDecisions(decisions);
      return true;
    }
    return false;
  }
}
