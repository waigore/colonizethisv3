import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show Game;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_spacing.dart';

/// Body of the "History" card — vertical list of [DiplomacyDetailLeftBorderTile]s,
/// newest first, or an italic muted empty-state.
class DiplomacyDetailHistorySection extends StatelessWidget {
  const DiplomacyDetailHistorySection({
    required this.history,
    required this.formatYear,
    required this.formatSentence,
    required this.l10n,
  });

  final List<DiplomaticEvent> history;
  final int Function(int turn) formatYear;
  final String Function(DiplomaticEvent e) formatSentence;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return DiplomacyDetailEmptyState(text: l10n.diplomacy_detail_noEvents);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final e in history)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: DiplomacyDetailLeftBorderTile(
              label: l10n.diplomacy_detail_yearTurn(formatYear(e.turn), e.turn),
              body: formatSentence(e),
            ),
          ),
      ],
    );
  }
}

/// Body of the "Dossier" card (Great Powers only).
class DiplomacyDetailDossierSection extends StatelessWidget {
  const DiplomacyDetailDossierSection({
    required this.game,
    required this.observerId,
    required this.subjectId,
    required this.l10n,
  });

  final Game game;
  final String observerId;
  final String subjectId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final entries = game.dossierEvidenceEntries
        .where((e) => e.observerId == observerId && e.subjectId == subjectId)
        .toList();
    entries.sort((a, b) {
      final t = b.turnNumber.compareTo(a.turnNumber);
      if (t != 0) return t;
      return a.description.compareTo(b.description);
    });

    if (entries.isEmpty) {
      return DiplomacyDetailEmptyState(text: l10n.diplomacy_detail_noDossier);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: DiplomacyDetailLeftBorderTile(
              label: l10n.diplomacy_detail_turnEvidence(e.turnNumber),
              body: e.description,
            ),
          ),
      ],
    );
  }
}

/// Pixel-art tile used by the history and dossier lists. Mirrors mockup
/// `.event` / `.dossier` rules: `--surface` background, 2 px `--accent-dim`
/// left border, monospace `--accent-dim` label, `--fg` body sentence.
class DiplomacyDetailLeftBorderTile extends StatelessWidget {
  const DiplomacyDetailLeftBorderTile({
    required this.label,
    required this.body,
  });

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle bodyBase =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.surface,
        border: Border(
          left: BorderSide(
            color: EditorialMonoclePalette.accentDim,
            width: 2,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CtSpacing.ml,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontFamilyFallback: <String>['Courier'],
                fontSize: 11,
              ).copyWith(color: EditorialMonoclePalette.accentDim),
            ),
            const SizedBox(height: 3),
            Text(
              body,
              style: bodyBase.copyWith(
                color: EditorialMonoclePalette.fg,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Italic muted empty-state line shared by the history and dossier sections.
class DiplomacyDetailEmptyState extends StatelessWidget {
  const DiplomacyDetailEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle base =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: base.copyWith(
          color: EditorialMonoclePalette.muted,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
