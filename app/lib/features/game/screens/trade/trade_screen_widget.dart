/// Full-screen World Market trade screen.
///
/// Dark editorial-monocle chrome per `SPEC/ui/trade-screen.md` § Top bar: a
/// `CtTopBar` carrying the `Map` back affordance, the 18 × 18 pixel-art
/// trade icon, and the literal title `Trade`. The body is a two-tab
/// `CtTabStrip` (Market + Deal Book). Widget keys and copy literals live on
/// [TradeScreenMarketKeys] / [TradeScreenDealBookKeys] (Refs #4035) — this
/// widget no longer re-declares that static surface.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../../widgets/game_feature_screen_top_bar.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../../widgets/shell/shell_player_guarded_body.dart';
import 'trade_screen_contract_market.dart';
import 'trade_screen_tabs_body.dart';

class TradeScreen extends ConsumerWidget {
  const TradeScreen({
    super.key,
    required this.game,
    required this.player,
    this.initialTabIndex = 0,
    this.highlightCommodityId,
  }) : assert(
         initialTabIndex >= 0 && initialTabIndex < 2,
         'initialTabIndex must be 0 (Market) or 1 (Deal Book) for TradeScreen',
       );

  /// Initially-selected tab index for the body's `CtTabStrip`. Defaults
  /// to `0` so the dark-theme E4 contract (Market tab visible on first
  /// mount) is preserved for the production route. Story builders /
  /// widget tests opt into the Deal Book tab (`1`) without simulating a
  /// label tap; the underlying `CtTabStrip.initialTabIndex` is the only
  /// surface that propagates the override.
  final int initialTabIndex;

  /// Market row to highlight and scroll into view (Production inbound).
  final String? highlightCommodityId;

  /// SPEC/ui/trade-screen.md — [UiScreenIds.tradeScreen].
  static const screenId = UiScreenIds.tradeScreen;

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CtGameFeatureScreenShell(
      game: game,
      topBar: GameFeatureScreenTopBar.build(
        key: TradeScreenMarketKeys.topBarKey,
        title: TradeScreenMarketKeys.topBarTitle,
        iconAsset: TradeScreenMarketKeys.topBarIconAsset,
      ),
      bodyBuilder: (context, shellRef, displayGame) {
        final shell = shellRef.read(shellPlayerContextProvider);
        // ignore: avoid_hardcoded_strings_in_widgets
        final sentinel = observeNotDefinedSentinel(shell, 'Trade');
        if (sentinel != null) return sentinel;
        final bool canEdit = shell.canMutateViaUi;
        return TradeScreenTabsBody(
          key: TradeScreenMarketKeys.tabsBodyKey,
          game: displayGame,
          playerId: player.id,
          canEdit: canEdit,
          initialTabIndex: initialTabIndex,
          highlightCommodityId: highlightCommodityId,
        );
      },
    );
  }
}
