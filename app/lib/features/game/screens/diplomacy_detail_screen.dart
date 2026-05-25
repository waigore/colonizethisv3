// Diplomacy detail: history + dossier for one faction. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/app_event_bus_provider.dart';
import '../../../widgets/ct_panel.dart';
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

/// Full-screen diplomacy detail: history list (newest first) and dossier for GP.
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

    return Scaffold(
      appBar: AppBar(
        title: Text(factionDisplayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => bus.emit(const PopNavigationEvent()),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _relationSummary(context, l10n),
          const SizedBox(height: 16),
          Text(
            l10n.diplomacy_detail_historyTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                l10n.diplomacy_detail_noEvents,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...history.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.diplomacy_detail_yearTurn(year(e.turn), e.turn),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDiplomaticEvent(e, game, humanPlayerId),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (kind == FactionKind.greatPower) ...[
            const SizedBox(height: 24),
            Text(
              l10n.diplomacy_detail_dossierTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _DossierSection(
              game: game,
              observerId: humanPlayerId,
              subjectId: factionId,
              l10n: l10n,
            ),
          ],
        ],
      ),
    );
  }

  Widget _relationSummary(BuildContext context, AppLocalizations l10n) {
    final stateLabel = relation == null
        ? '—'
        : relation!.atWar
        ? l10n.diplomacy_relationState_war
        : l10n.diplomacy_relationState_peace;
    final relationLabel = relation == null
        ? ''
        : relationScoreToDisplayLabel(relation!.score);
    return CtPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.diplomacy_detail_currentRelation,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            relationLabel.isEmpty ? stateLabel : '$stateLabel · $relationLabel',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

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
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          l10n.diplomacy_detail_noDossier,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.diplomacy_detail_turnEvidence(e.turnNumber),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
