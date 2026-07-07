// Full-screen Production screen. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_constants.dart';
import '../../../../config/ct_e2e.dart';
import '../../../../config/ct_e2e_last_panel_snapshot.dart';
import '../../../../config/editorial_monocle_palette.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/production_allocation_provider.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../../widgets/shell/shell_player_guarded_body.dart';
import '../../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../../widgets/ct_top_bar.dart';
import '../../../../widgets/strict_asset_icon.dart';
import '../../widgets/production/production_commodity_breakdown_dialog.dart';
import '../../widgets/production/production_labour_helpers.dart';
import '../../widgets/production/production_panel.dart';

part 'production_screen_body.dart';

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
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarBackLabel = 'Map';

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
      topBar: CtTopBar(
        key: topBarKey,
        title: topBarTitle,
        backButtonLabel: topBarBackLabel,
        icon: const StrictAssetIcon(
          assetPath: _topBarIconAsset,
          width: 18,
          height: 18,
        ),
      ),
      bodyBuilder: (context, shellRef, displayGame) =>
          buildProductionScreenBody(
            context: context,
            shellRef: shellRef,
            displayGame: displayGame,
            screen: this,
          ),
    );
  }
}
