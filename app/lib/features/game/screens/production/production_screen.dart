// Full-screen Production screen. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_constants.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../../widgets/game_feature_screen_top_bar.dart';
import 'production_screen_body.dart';

class ProductionScreen extends ConsumerWidget {
  const ProductionScreen({
    super.key,
    required this.game,
    required this.player,
    this.attachGameToUiListener = true,
    this.panelTopologyOverride,
    this.panelTileMapByRegionOverride,
  });

  /// SPEC/ui/production-panel.md — [UiScreenIds.productionScreen].
  static const screenId = UiScreenIds.productionScreen;

  final Game game;
  final Player player;

  /// When true (default), [GameToUIBusListener] subscribes to turn-complete events.
  /// Set false in isolated widget tests where the listener tree affects layout.
  final bool attachGameToUiListener;

  /// When set, the production panel uses this topology instead of
  /// [GameService.getMapData] (avoids Hive in tests).
  final MapTopology? panelTopologyOverride;

  /// Optional tile maps when [panelTopologyOverride] is set.
  final Map<String, TileMapResult>? panelTileMapByRegionOverride;

  /// Localized back-button label rendered immediately after the chevron
  /// on the dark-theme `CtTopBar`. SPEC/ui/production-panel.md § Top bar
  /// requires the literal `"Map"` so the affordance reads `"← Map"`.
  /// Exposed so widget tests (notably the 320 dp viewport pin) can
  /// assert against the SPEC string without coupling to the localization
  /// indirection or duplicating the literal — mirrors the pattern used
  /// by `TradeScreen`, `DiplomacyScreen`, and `TechnologyScreen`.
  static const String topBarBackLabel = GameFeatureScreenTopBar.backLabel;

  /// Title text shown in the dark-theme `CtTopBar`. SPEC mandates the
  /// literal `"Production"` (Cinzel display font is configured at the
  /// theme level). Exposed so widget tests can match against the SPEC
  /// string — see [topBarBackLabel] for the same rationale.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarTitle = 'Production';

  /// Pixel-art icon asset rendered between the back affordance and the
  /// title (SPEC § Top bar — 18 px production icon).
  static const String _topBarIconAsset =
      '${kAppIconAssetPrefix}ui_icon_production.png';

  /// Stable widget key for the production top bar — lets widget tests
  /// pin the dark-theme chrome without coupling to localized strings.
  static const Key topBarKey = ValueKey<String>('productionScreenTopBar');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CtGameFeatureScreenShell(
      game: game,
      attachGameToUiListener: attachGameToUiListener,
      topBar: GameFeatureScreenTopBar.build(
        key: topBarKey,
        title: topBarTitle,
        iconAsset: _topBarIconAsset,
      ),
      bodyBuilder: (context, shellRef, displayGame) => ProductionScreenBody(
        displayGame: displayGame,
        screen: this,
      ),
    );
  }
}
