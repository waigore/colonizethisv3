import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review_labels.dart';
import 'package:colonizethis_app/widgets/commodity_display_name.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

StagedDecreeFamilyGroup stagedDecreeTradeFamily(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final list =
      orders.tradeOrdersByPlayerId[humanPlayerId] ?? const <TradeOrder>[];
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.trade,
    familyLabel: l10n.game_nextTurnConfirm_familyTrade,
    rows: [
      for (var i = 0; i < list.length; i++)
        StagedDecreeRow(
          id: 'trade-$i-${list[i].type.name}-${list[i].commodityId}',
          label: list[i].type == TradeOrderType.bid
              ? l10n.tradeCounsel_title_bid(
                  commodityDisplayName(l10n, list[i].commodityId),
                  list[i].quantity,
                )
              : l10n.tradeCounsel_title_offer(
                  commodityDisplayName(l10n, list[i].commodityId),
                  list[i].quantity,
                ),
        ),
    ],
  );
}

StagedDecreeFamilyGroup stagedDecreeResearchFamily(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final raw =
      orders.researchOrdersByPlayerId[humanPlayerId] ?? const <ResearchOrder>[];
  final listed = raw
      .where(
        (o) => o.techId.isNotEmpty && o.funding != ResearchFundingLevel.none,
      )
      .toList();
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.research,
    familyLabel: l10n.game_nextTurnConfirm_familyResearch,
    rows: [
      for (var i = 0; i < listed.length; i++)
        StagedDecreeRow(
          id: 'research-$i-${listed[i].slotIndex}-${listed[i].techId}',
          label: l10n.game_nextTurnConfirm_rowResearch(
            techDisplayName(listed[i].techId),
            stagedDecreeFundingLabel(l10n, listed[i].funding),
          ),
        ),
    ],
  );
}
