part of 'diplomacy_detail_screen.dart';

/// Inner heading inside a `_DetailCard`. Matches the GAME30002 mockup
/// `.card h3` rule (display font, 13 px, `--muted`, uppercase, letter-spacing
/// 0.06 em). Separate from `CtSectionLabel` because card titles do not paint
/// a bottom border on the mockup.
class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseDisplay =
        theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: baseDisplay.copyWith(
          color: EditorialMonoclePalette.muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.06 * 13,
        ),
      ),
    );
  }
}

/// Framed card with gradient background (`--surface-lite → --surface →
/// --bg-deep`) and a 1 px `--border` outline. Mirrors mockup `.card`.
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const <double>[0.0, 0.3, 1.0],
          colors: <Color>[
            EditorialMonoclePalette.surfaceLite,
            EditorialMonoclePalette.surface,
            EditorialMonoclePalette.bgDeep,
          ],
        ),
        border: Border.all(color: EditorialMonoclePalette.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _CardTitle(title),
            child,
          ],
        ),
      ),
    );
  }
}

/// Body of the "Current relation" card. Renders a one-line summary with a
/// War/Peace state (colored badge label) and the one-word relation label.
class _RelationSummary extends StatelessWidget {
  const _RelationSummary({
    required this.relation,
    required this.l10n,
    this.standingChips = const DiplomaticStandingChips(),
  });

  final DiplomacyRelation? relation;
  final AppLocalizations l10n;

  /// Active overture/treaty/colony/boycott/overseas chips for this faction
  /// (Refs #3753 R12). Rendered below the relation summary when non-empty.
  final DiplomaticStandingChips standingChips;

  @override
  Widget build(BuildContext context) {
    final DiplomacyRelation? rel = relation;
    if (rel == null) {
      return Text(
        '—',
        style: _relationSummaryDisplayStyle(context).copyWith(
          color: EditorialMonoclePalette.muted,
        ),
      );
    }
    final Widget summaryRow = _RelationSummaryRow(relation: rel, l10n: l10n);
    if (standingChips.isEmpty) {
      return summaryRow;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        summaryRow,
        const SizedBox(height: 8),
        DiplomacyStandingChipCluster(chips: standingChips),
      ],
    );
  }
}

/// One-line War/Peace state, relation meter, one-word ladder label, and the
/// optional formal-alliance badge. Extracted from [_RelationSummary] to keep
/// each `build` body within the widget-size lint budget.
class _RelationSummaryRow extends StatelessWidget {
  const _RelationSummaryRow({required this.relation, required this.l10n});

  final DiplomacyRelation relation;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final bool atWar = relation.atWar;
    final String stateLabel = atWar
        ? l10n.diplomacy_relationState_war
        : l10n.diplomacy_relationState_peace;
    final Color stateColor = atWar
        ? EditorialMonoclePalette.danger
        : EditorialMonoclePalette.success;
    final String relationLabel = relationScoreToDisplayLabel(relation.score);
    // SPEC/ui/diplomacy-detail-screen.md § Formal alliance indicator
    // (Refs #3625, AC4): a persisted formal alliance surfaces the same gold
    // ALLIANCE treaty badge used by the panel row, distinct from the informal
    // one-word relation label. A merely-Friendly relation in the informal
    // RelationLevel.allied band (no treaty) never shows it.
    final bool showAlliance = relation.formalAlliance;

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          stateLabel,
          style: _relationSummaryDisplayStyle(context).copyWith(
            color: stateColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        // SPEC/ui/diplomacy-detail-screen.md § Current relation (Refs #3753
        // R13.5): the same 10-step gradient meter used on the panel row sits
        // beside the one-word ladder label; the hidden decimal score positions
        // the indicator.
        RelationMeter(score: relation.score),
        if (relationLabel.isNotEmpty)
          Text(
            relationLabel,
            style: _relationSummaryDisplayStyle(context).copyWith(
              color: relationMeterStepColor(
                relationScoreToMeterStep(relation.score),
              ),
            ),
          ),
        if (showAlliance) const DiplomacyAllianceBadge(),
      ],
    );
  }
}

TextStyle _relationSummaryDisplayStyle(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  return (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
      .copyWith(letterSpacing: 0.02);
}

/// Body of the "History" card — vertical list of [_LeftBorderTile]s, newest
/// first, or an italic muted empty-state.
class _HistorySection extends StatelessWidget {
  const _HistorySection({
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
      return _EmptyState(text: l10n.diplomacy_detail_noEvents);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final e in history)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _LeftBorderTile(
              label: l10n.diplomacy_detail_yearTurn(formatYear(e.turn), e.turn),
              body: formatSentence(e),
            ),
          ),
      ],
    );
  }
}

/// Body of the "Dossier" card (Great Powers only). Reuses [_LeftBorderTile]
/// chrome so dossier rows match the mockup `.dossier` rule (left border, mono
/// turn label, body sentence).
class _DossierSection extends StatelessWidget {
  const _DossierSection({
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
      return _EmptyState(text: l10n.diplomacy_detail_noDossier);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _LeftBorderTile(
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
class _LeftBorderTile extends StatelessWidget {
  const _LeftBorderTile({required this.label, required this.body});

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
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

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
