
import 'package:colonizethis_app_ui_chrome/colonizethis_app_ui_chrome.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../widgets/commodity_display_name.dart';
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
    return buildCtTurnFeedEntries(
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
        economyTurnSummaryTap: economyTurnSummaryTap(),
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
        .toList(growable: false);
  }
}
