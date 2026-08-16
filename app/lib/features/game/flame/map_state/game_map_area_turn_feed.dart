
import 'package:colonizethis_app_ui_chrome/colonizethis_app_ui_chrome.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../widgets/commodity_display_name.dart';
import '../../screens/diplomacy/intelligence_council_format.dart';
import '../../widgets/shell/player_turn_event_feed.dart';
import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_turn_feed_labels.dart';
import 'game_map_area_turn_feed_taps.dart';

/// Player turn-event feed for [GameMapArea]: turning resolved `GameToUIEvent`s
/// into tappable feed entries (Refs #3699 Theme 3).
mixin GameMapAreaTurnFeed
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaTurnFeedLabels,
        GameMapAreaTurnFeedTaps {
  List<PlayerTurnEventFeedEntry> buildFeedEntries() {
    final mapped = buildCtTurnFeedEntries(
      events: resolvedPlayerTurnEvents,
      context: CtTurnFeedEntryContext(
        mapPlayerId: mapPlayerId,
        factionLabel: factionLabel,
        provinceLabel: provinceLabel,
        seaZoneLabel: seaZoneLabel,
        diplomacyOutcomeLine: diplomacyOutcomeLine,
        isCatalogTech: isCatalogTech,
        researchCompleteLine: researchCompleteLine,
        navigateToTechnologyScreen: navigateToTechnologyScreen,
        workTargetLabel: workTargetLabel,
        overtureStageLabel: overtureStageLabel,
        locateProvinceById: locateProvinceById,
        locateSeaZoneTile: locateSeaZoneTile,
        counterpartFactionId: counterpartFactionId,
        overtureCounterpartFactionId: overtureCounterpartFactionId,
        spyCounterpartFactionId: spyCounterpartFactionId,
        diplomacyDetailTapForFaction: diplomacyDetailTapForFaction,
        provinceOverlayTapForProvince: provinceOverlayTapForProvince,
        navalCombatTapForSeaZone: navalCombatTapForSeaZone,
        workOrderCompletedTap: workOrderCompletedTap,
        overseasProfitCreditedTap: overseasProfitCreditedTap(),
        economyTurnSummaryTap: productionPanelTap(),
        commodityDisplayName: (commodityId) =>
            commodityDisplayName(appL10n(context), commodityId),
        orderRejectedTapForKind: orderRejectedTapForKind,
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
    if (digest == null) return List<PlayerTurnEventFeedEntry>.unmodifiable(mapped);
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
