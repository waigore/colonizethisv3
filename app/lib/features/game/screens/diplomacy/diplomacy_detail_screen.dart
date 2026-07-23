// Diplomacy detail: history + dossier for one faction. SPEC/ui/diplomacy-detail-screen.md.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/ct_top_bar.dart';
import '../../../../widgets/relation_meter.dart';
import '../../widgets/diplomacy/diplomacy_panel.dart';

part 'diplomacy_detail_screen_format.dart';
part 'diplomacy_detail_screen_widgets_cards.dart';
part 'diplomacy_detail_screen_widgets_relation.dart';
part 'diplomacy_detail_screen_widgets_sections.dart';

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
    // SPEC/ui/diplomacy-detail-screen.md § Current relation: Great Power
    // targets show the same relative-power line as the panel row above the
    // relation summary; Minor / Tribe targets omit it.
    final int? relativePowerPct = kind == FactionKind.greatPower
        ? powerComparisonPercent(
            greatPowerPowerScore(game, factionId),
            greatPowerPowerScore(game, humanPlayerId),
          )
        : null;
    // SPEC/ui/diplomacy-detail-screen.md § Current relation (Refs #3753 R12):
    // the CURRENT RELATION card shows the same overture/treaty/colony/boycott/
    // overseas chip cluster as the diplomacy-panel.md row.
    final DiplomaticStandingChips standingChips = diplomaticStandingChips(
      game: game,
      humanPlayerId: humanPlayerId,
      factionId: factionId,
      kind: kind,
      relation: relation,
      overture: getOverture(game, humanPlayerId, factionId),
      purchasedTiles: PurchasedTileIndex.fromGame(game),
    );

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (relativePowerPct != null) ...<Widget>[
                        RelativePowerLine(pct: relativePowerPct),
                        const SizedBox(height: 8),
                      ],
                      _RelationSummary(
                        relation: relation,
                        l10n: l10n,
                        standingChips: standingChips,
                      ),
                    ],
                  ),
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
