// Two-tab body chrome for the World Market trade screen.

/// Two-tab body for the trade screen: Market (default) + Deal Book.
///
/// Hosts a [CtTabStrip] inside a [CtPanel] so the dark editorial-monocle
/// surface mirrors the chrome already established for sibling
/// full-screen feature surfaces (production, diplomacy). The Market tab
/// now renders the interactive bid/offer/none + quantity stepper row
/// sourced from [Game.worldMarketState] + `currentOrdersProvider`
/// (Refs #2993 E5a + E5b); the Deal Book tab keeps the placeholder copy
/// until the per-player ledger work for Refs #2993 E6 lands. The
/// two-tab structure stays as the durable wireframe so the follow-up
/// cargo indicator + priority dropdown + Deal Book ledger slices can
/// swap each tab body in place without remounting the strip.

import 'package:flutter/material.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../widgets/ct_panel.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/ct_tab_strip.dart';
import 'trade_screen_contract_deal_book.dart';
import 'trade_screen_contract_market.dart';
import 'trade_screen_deal_book.dart';
import 'trade_screen_market_tab.dart';

class TradeScreenTabsBody extends StatelessWidget {
  const TradeScreenTabsBody({
    super.key,
    required this.game,
    required this.playerId,
    required this.canEdit,
    this.initialTabIndex = 0,
  });

  final Game game;
  final String playerId;
  final bool canEdit;
  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: CtPanel(
        padding: const EdgeInsets.all(CtSpacing.l),
        child: CtTabStrip(
          initialTabIndex: initialTabIndex,
          tabLabels: const <String>[
            TradeScreenMarketKeys.marketTabLabel,
            TradeScreenDealBookKeys.dealBookTabLabel,
          ],
          tabViews: <Widget>[
            MarketTabContent(
              key: TradeScreenMarketKeys.marketTabBodyKey,
              game: game,
              playerId: playerId,
              canEdit: canEdit,
            ),
            DealBookTabContent(
              key: TradeScreenDealBookKeys.dealBookTabBodyKey,
              game: game,
              playerId: playerId,
            ),
          ],
        ),
      ),
    );
  }
}
