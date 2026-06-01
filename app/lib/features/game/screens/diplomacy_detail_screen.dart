// Diplomacy detail: history + dossier for one faction. SPEC/ui/diplomacy-detail-screen.md.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/app_event_bus_provider.dart';
import '../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../widgets/ct_top_bar.dart';
import '../widgets/diplomacy_panel.dart';

/// Human-readable sentence for a diplomatic event. Unknown factions shown as "Unknown faction".
String formatDiplomaticEvent(
  DiplomaticEvent e,
  Game game,
  String humanPlayerId,
) {
  String name(String factionId) {
    if (factionId == humanPlayerId) return 'We';
    if (getRelation(game, humanPlayerId, factionId) == null) {
      return 'Unknown faction';
    }
    final p = game.playerById(factionId);
    if (p != null) return p.displayName;
    for (final m in game.minorNations) {
      if (m.id == factionId) return m.displayName ?? factionId;
    }
    for (final t in game.tribes) {
      if (t.id == factionId) return t.displayName ?? factionId;
    }
    return factionId;
  }

  final from = e.fromFactionId != null ? name(e.fromFactionId!) : null;
  final to = e.toFactionId != null ? name(e.toFactionId!) : null;
  final stage = e.overtureStage != null
      ? _overtureLabel(e.overtureStage!)
      : null;

  switch (e.type) {
    case DiplomaticEventType.declareWar:
      return '${from ?? 'Unknown'} declared war on ${to ?? 'Unknown'}.';
    case DiplomaticEventType.peace:
      return '${from ?? 'Unknown'} made peace with ${to ?? 'Unknown'}.';
    case DiplomaticEventType.allianceFormed:
      return '${from ?? 'Unknown'} formed an alliance with ${to ?? 'Unknown'}.';
    case DiplomaticEventType.allianceBroken:
      return 'Alliance between ${from ?? 'Unknown'} and ${to ?? 'Unknown'} ended.';
    case DiplomaticEventType.overtureAccepted:
      return '${from ?? 'Unknown'} established ${stage ?? 'overture'} with ${to ?? 'Unknown'}.';
    case DiplomaticEventType.overtureRejected:
      return '${to ?? 'Unknown'} rejected ${stage ?? 'overture'} from ${from ?? 'Unknown'}.';
    case DiplomaticEventType.joinEmpireResolved:
      return '${from ?? 'Unknown'} absorbed ${to ?? 'Unknown'} (Join Empire).';
    case DiplomaticEventType.grantAidApplied:
      final amt = e.amount ?? 0;
      return '${from ?? 'Unknown'} granted £$amt aid to ${to ?? 'Unknown'}.';
    case DiplomaticEventType.subsidySet:
      return '${from ?? 'Unknown'} set subsidy of £${e.amount ?? 0}/turn to ${to ?? 'Unknown'}.';
    case DiplomaticEventType.subsidyUpdated:
      return '${from ?? 'Unknown'} updated subsidy to £${e.amount ?? 0}/turn to ${to ?? 'Unknown'}.';
    case DiplomaticEventType.subsidyCancelled:
      return 'Subsidy ${from ?? 'Unknown'} → ${to ?? 'Unknown'} ended (${e.reason ?? 'cancelled'}).';
    case DiplomaticEventType.interventionIntervene:
      return '${from ?? 'Unknown'} intervened in war (against ${to ?? 'Unknown'}).';
    case DiplomaticEventType.interventionDoNothing:
      return '${from ?? 'Unknown'} did not intervene (against ${to ?? 'Unknown'}).';
    case DiplomaticEventType.interventionProtest:
      return '${from ?? 'Unknown'} protested (against ${to ?? 'Unknown'}).';
    case DiplomaticEventType.agreementsClearedOnWar:
      return 'Overtures between ${from ?? 'Unknown'} and ${to ?? 'Unknown'} ended due to war.';
    case DiplomaticEventType.callToArmsAccepted:
      return '${from ?? 'Unknown'} joined the war against ${to ?? 'Unknown'} (call to arms).';
    case DiplomaticEventType.callToArmsRefused:
      return '${from ?? 'Unknown'} refused call to arms; alliance with ${to ?? 'Unknown'} ended.';
    case DiplomaticEventType.ftpFormed:
      return '${from ?? 'Unknown'} established a free trade partnership with ${to ?? 'Unknown'}.';
    case DiplomaticEventType.ftpBroken:
      return 'Free trade partnership between ${from ?? 'Unknown'} and ${to ?? 'Unknown'} ended (${e.reason ?? 'cancelled'}).';
  }
}

String _overtureLabel(OvertureStage s) {
  return switch (s) {
    OvertureStage.none => 'overture',
    OvertureStage.tradeConsulate => 'Trade Consulate',
    OvertureStage.embassy => 'Embassy',
    OvertureStage.nap => 'Non-Aggression Pact',
    OvertureStage.joinEmpire => 'Join Empire',
  };
}

/// Full-screen diplomacy detail. Dark editorial-monocle chrome per
/// `SPEC/ui/diplomacy-detail-screen.md` and `SPEC/ui/mockups/GAME30002-…html`.
class DiplomacyDetailScreen extends ConsumerWidget {
  const DiplomacyDetailScreen({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.factionId,
    required this.factionDisplayName,
    required this.kind,
    required this.relation,
  });

  static const screenId = UiScreenIds.diplomacyDetailScreen;

  /// Max content column width per the GAME30002 mockup `.content` rule
  /// (`max-width: 600px`).
  static const double contentMaxWidth = 600;

  /// Outer horizontal/vertical padding inside the content column.
  static const double contentPadding = 14;

  /// Spacing between stacked cards.
  static const double cardSpacing = 14;

  final Game game;
  final String humanPlayerId;
  final String factionId;
  final String factionDisplayName;
  final FactionKind kind;
  final DiplomacyRelation? relation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = appL10n(context);
    final bus = ref.watch(appEventBusProvider);
    final history = diplomaticHistoryForPair(game, humanPlayerId, factionId);
    int year(int turn) => turnToYear(turn, game.turnTimeMapping);

    return CtGameFeatureScreenShell(
      game: game,
      attachGameToUiListener: false,
      backgroundColor: EditorialMonoclePalette.bg,
      topBar: CtTopBar(
        title: factionDisplayName,
        onBackPressed: () => bus.emit(const PopNavigationEvent()),
      ),
      bodyBuilder: (BuildContext context, WidgetRef _, Game _) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: contentPadding,
                vertical: contentPadding,
              ),
              children: <Widget>[
                _DetailCard(
                  title: l10n.diplomacy_detail_currentRelation,
                  child: _RelationSummary(relation: relation, l10n: l10n),
                ),
                const SizedBox(height: cardSpacing),
                _DetailCard(
                  title: l10n.diplomacy_detail_historyTitle,
                  child: _HistorySection(
                    history: history,
                    formatYear: year,
                    formatSentence: (e) =>
                        formatDiplomaticEvent(e, game, humanPlayerId),
                    l10n: l10n,
                  ),
                ),
                if (kind == FactionKind.greatPower) ...<Widget>[
                  const SizedBox(height: cardSpacing),
                  _DetailCard(
                    title: l10n.diplomacy_detail_dossierTitle,
                    child: _DossierSection(
                      game: game,
                      observerId: humanPlayerId,
                      subjectId: factionId,
                      l10n: l10n,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

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
  const _RelationSummary({required this.relation, required this.l10n});

  final DiplomacyRelation? relation;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (relation == null) {
      return Text(
        '—',
        style: _displayStyle(context).copyWith(
          color: EditorialMonoclePalette.muted,
        ),
      );
    }
    final bool atWar = relation!.atWar;
    final String stateLabel = atWar
        ? l10n.diplomacy_relationState_war
        : l10n.diplomacy_relationState_peace;
    final Color stateColor = atWar
        ? EditorialMonoclePalette.danger
        : EditorialMonoclePalette.success;
    final String relationLabel = relationScoreToDisplayLabel(relation!.score);

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          stateLabel,
          style: _displayStyle(context).copyWith(
            color: stateColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (relationLabel.isNotEmpty)
          Text(
            relationLabel,
            style: _displayStyle(context).copyWith(
              color: EditorialMonoclePalette.fg,
            ),
          ),
      ],
    );
  }

  TextStyle _displayStyle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
        .copyWith(letterSpacing: 0.02);
  }
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
