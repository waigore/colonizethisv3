// Pending intervention: Diplomacy-phase choices when a GP attacks Minor/Tribe.
// SPEC/tui/screens/pending-intervention.md, SPEC/program/dialogue-system.md.

import 'package:ctterm/package_logger.dart';
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final _log = packageLogger();

/// Builds the rows submitted when the player confirms all prompts (Enter).
/// SPEC/tui/screens/pending-intervention.md.
List<InterventionDecision> buildInterventionDecisionsForSubmit({
  required List<InterventionPrompt> prompts,
  required List<InterventionChoice> choices,
}) {
  if (prompts.length != choices.length) {
    throw ArgumentError(
      'prompts (${prompts.length}) and choices (${choices.length}) length mismatch',
    );
  }
  return List<InterventionDecision>.generate(prompts.length, (i) {
    final p = prompts[i];
    return InterventionDecision(
      aggressorGpId: p.aggressorGpId,
      defenderMinorOrTribeId: p.defenderMinorOrTribeId,
      interveningGpId: p.interveningGpId,
      choice: choices[i],
    );
  });
}

/// Blocking screen: human chooses intervene / do naught / protest per prompt.
class PendingInterventionScreen extends StatefulComponent {
  const PendingInterventionScreen({
    super.key,
    required this.game,
    required this.prompts,
    required this.onDecisions,
  });

  final Game game;
  final List<InterventionPrompt> prompts;
  final void Function(List<InterventionDecision> decisions) onDecisions;

  @override
  State<PendingInterventionScreen> createState() =>
      _PendingInterventionScreenState();
}

class _PendingInterventionScreenState extends State<PendingInterventionScreen> {
  int _selectedIndex = 0;
  late List<InterventionChoice> _choices;

  @override
  void initState() {
    super.initState();
    _choices = List<InterventionChoice>.filled(
      component.prompts.length,
      InterventionChoice.doNothing,
    );
  }

  String _factionName(String id) {
    final g = component.game;
    for (final p in g.players) {
      if (p.id == id) return p.displayName;
    }
    for (final m in g.minorNations) {
      if (m.id == id) return m.displayName ?? m.id;
    }
    for (final t in g.tribes) {
      if (t.id == id) return t.displayName ?? t.id;
    }
    return id;
  }

  static String _choiceLabel(InterventionChoice c) {
    switch (c) {
      case InterventionChoice.intervene:
        return 'Intervene';
      case InterventionChoice.doNothing:
        return 'Do naught';
      case InterventionChoice.protest:
        return 'Protest';
    }
  }

  @override
  Component build(BuildContext context) {
    final prompts = component.prompts;
    if (prompts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(1),
        child: Text('No pending intervention.'),
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
            const Text(
              'War and intervention',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Grave news: a sovereign hath made war upon a lesser state wherein '
              'thy nation hath embassy, commerce, or bond. The Crown awaiteth thy '
              'answer ere the turn proceedeth.',
            ),
            const SizedBox(height: 1),
            ...List.generate(prompts.length, (i) {
              final p = prompts[i];
              final sel = i == _selectedIndex;
              final prefix = sel ? '> ' : '  ';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Text(
                  '$prefix${_factionName(p.aggressorGpId)} vs '
                  '${_factionName(p.defenderMinorOrTribeId)} '
                  '(thy voice: ${_factionName(p.interveningGpId)}): '
                  '${_choiceLabel(_choices[i])}',
                ),
              );
            }),
            const SizedBox(height: 2),
            const Text(
              '[I] Intervene  [O] Do naught  [P] Protest  [Up/Down] Select  [Enter] Submit',
            ),
          ],
        ),
      ),
    );
  }

  // ignore: strict_top_level_inference
  bool _handleKeyEvent(event) {
    final key = event.logicalKey;
    final c = event.character?.toLowerCase();
    final n = component.prompts.length;
    if (n == 0) return false;

    if (c == 'i') {
      setState(() => _choices[_selectedIndex] = InterventionChoice.intervene);
      return true;
    }
    if (c == 'o') {
      setState(() => _choices[_selectedIndex] = InterventionChoice.doNothing);
      return true;
    }
    if (c == 'p') {
      setState(() => _choices[_selectedIndex] = InterventionChoice.protest);
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
      final decisions = buildInterventionDecisionsForSubmit(
        prompts: component.prompts,
        choices: _choices,
      );
      _log.d('submitting ${decisions.length} decision(s)');
      component.onDecisions(decisions);
      return true;
    }
    return false;
  }
}
