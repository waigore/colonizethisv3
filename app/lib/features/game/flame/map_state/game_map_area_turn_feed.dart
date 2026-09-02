import 'package:colonizethis_app_ui_chrome/colonizethis_app_ui_chrome.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../widgets/commodity_display_name.dart';
import '../../screens/diplomacy/intelligence_council_format.dart';
import '../../widgets/shell/player_turn_event_feed.dart';
import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_turn_feed_labels.dart';
import 'game_map_area_turn_feed_locate.dart';
import 'game_map_area_turn_feed_taps.dart';
import 'player_turn_event_feed_session_cache.dart';

/// Player turn-event feed for [GameMapArea]: turning resolved `GameToUIEvent`s
/// into tappable feed entries (Refs #3699 Theme 3).
mixin GameMapAreaTurnFeed
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaTurnFeedLabels,
        GameMapAreaTurnFeedLocate,
        GameMapAreaTurnFeedTaps {
  int committedFeedTurnNumber() =>
      playerTurnFeedCommittedTurnNumber ??
      widget.game.worldState.turnState.turnNumber;

  int cheapFeedBadgeCount() {
    final gameId = widget.game.id;
    final turnNumber = committedFeedTurnNumber();
    final eventCount = resolvedPlayerTurnEvents.length + _spyDigestLineCount();
    return PlayerTurnEventFeedSessionCache.readBadgeCount(
      gameId: gameId,
      committedTurnNumber: turnNumber,
      fallbackCount: eventCount,
    );
  }

  List<PlayerTurnEventFeedEntry> feedEntriesForMapBuild({
    required bool feedVisible,
  }) {
    if (!feedVisible) {
      return const [];
    }
    return ensureFormattedFeedEntries();
  }

  List<PlayerTurnEventFeedEntry> ensureFormattedFeedEntries() {
    final gameId = widget.game.id;
    final turnNumber = committedFeedTurnNumber();
    final cached = PlayerTurnEventFeedSessionCache.readFormatted(
      gameId: gameId,
      committedTurnNumber: turnNumber,
    );
    if (cached != null) {
      return cached;
    }
    final formatted = buildFeedEntries();
    PlayerTurnEventFeedSessionCache.storeFormatted(
      gameId: gameId,
      committedTurnNumber: turnNumber,
      entries: formatted,
      badgeCount: formatted.length,
    );
    return formatted;
  }

  int _spyDigestLineCount() {
    final digest = widget.game.lastTurnIntelligenceDigest;
    if (digest == null) {
      return 0;
    }
    var count = 0;
    for (final block in digest.spyReportsFor(mapPlayerId)) {
      count += block.lines.length;
    }
    return count;
  }

  List<PlayerTurnEventFeedEntry> buildFeedEntries() {
    final mapped =
        buildCtTurnFeedEntries(
              events: resolvedPlayerTurnEvents,
              context: CtTurnFeedEntryContext(
                labels: CtTurnFeedEntryLabels(
                  mapPlayerId: mapPlayerId,
                  factionLabel: factionLabel,
                  provinceLabel: provinceLabel,
                  seaZoneLabel: seaZoneLabel,
                  diplomacyOutcomeLine: diplomacyOutcomeLine,
                  isCatalogTech: isCatalogTech,
                  researchCompleteLine: researchCompleteLine,
                  workTargetLabel: workTargetLabel,
                  overtureStageLabel: overtureStageLabel,
                  commodityDisplayName: (commodityId) =>
                      commodityDisplayName(appL10n(context), commodityId),
                ),
                navigation: CtTurnFeedEntryNavigation(
                  navigateToTechnologyScreen: navigateToTechnologyScreen,
                  locateProvinceById: locateProvinceById,
                  locateSeaZoneTile: locateSeaZoneTile,
                ),
                taps: CtTurnFeedEntryTaps(
                  counterpartFactionId: counterpartFactionId,
                  overtureCounterpartFactionId: overtureCounterpartFactionId,
                  spyCounterpartFactionId: spyCounterpartFactionId,
                  diplomacyDetailTapForFaction: diplomacyDetailTapForFaction,
                  provinceOverlayTapForProvince: provinceOverlayTapForProvince,
                  navalCombatTapForSeaZone: navalCombatTapForSeaZone,
                  workOrderCompletedTap: workOrderCompletedTap,
                  overseasProfitCreditedTap: overseasProfitCreditedTap(),
                  economyTurnSummaryTap: productionPanelTap(),
                  orderRejectedTapForKind: orderRejectedTapForKind,
                ),
              ),
            )
            .map(
              (CtEventFeedEntry entry) => PlayerTurnEventFeedEntry(
                text: entry.text,
                onTap: entry.onTap,
                linkAffordance: entry.linkAffordance,
              ),
            )
            .toList();
    final digest = widget.game.lastTurnIntelligenceDigest;
    if (digest == null) {
      return List<PlayerTurnEventFeedEntry>.unmodifiable(mapped);
    }
    final l10n = appL10n(context);
    for (final block in digest.spyReportsFor(mapPlayerId)) {
      for (final line in block.lines) {
        mapped.add(
          PlayerTurnEventFeedEntry(
            text: formatIntelligenceSpyLine(
              l10n,
              widget.game,
              mapPlayerId,
              block.courtFactionId,
              line,
            ),
            onTap: navigateToIntelligenceCouncil,
            linkAffordance: true,
          ),
        );
      }
    }
    return List<PlayerTurnEventFeedEntry>.unmodifiable(mapped);
  }
}
