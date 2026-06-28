// Full-screen Diplomacy screen. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../providers/app_event_bus_provider.dart';
import '../../../providers/game_service_provider.dart';
import '../../../providers/games_provider.dart';
import '../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../widgets/ct_top_bar.dart';
import '../../../widgets/strict_asset_icon.dart';
import '../shell_player_context.dart' show shellPlayerContextProvider;
import '../widgets/shell_player_guarded_body.dart';
import '../widgets/diplomacy_panel.dart';
import '../widgets/grant_or_subsidy_listener.dart';

class DiplomacyScreen extends ConsumerWidget {
  const DiplomacyScreen({
    super.key,
    required this.game,
    required this.humanPlayerId,
  });

  /// SPEC/ui/diplomacy-panel.md — [UiScreenIds.diplomacyScreen].
  static const screenId = UiScreenIds.diplomacyScreen;

  /// Localized back-button label rendered immediately after the chevron
  /// on the dark-theme `CtTopBar`. SPEC/ui/diplomacy-panel.md § Top bar
  /// requires the literal `"Map"` so the affordance reads `"← Map"`.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarBackLabel = 'Map';

  /// Title text shown in the dark-theme `CtTopBar`. SPEC mandates the
  /// literal `"Diplomacy"` (Cinzel display font is configured at the
  /// theme level).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarTitle = 'Diplomacy';

  /// Pixel-art icon asset rendered between the back affordance and the
  /// title (SPEC § Top bar — 18 × 18 px diplomacy icon).
  static const String topBarIconAsset =
      '${kAppIconAssetPrefix}ui_icon_diplomacy.png';

  /// Stable widget key for the diplomacy top bar — lets widget tests pin
  /// the dark-theme chrome without coupling to localized strings.
  static const Key topBarKey = ValueKey<String>('diplomacyScreenTopBar');

  final Game game;
  final String humanPlayerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bus = ref.watch(appEventBusProvider);
    return CtGameFeatureScreenShell(
      game: game,
      topBar: const CtTopBar(
        key: topBarKey,
        title: topBarTitle,
        backButtonLabel: topBarBackLabel,
        icon: StrictAssetIcon(
          assetPath: topBarIconAsset,
          width: 18,
          height: 18,
        ),
      ),
      bodyBuilder: (context, shellRef, displayGame) {
        final shell = shellRef.read(shellPlayerContextProvider);
        final sentinel = observeNotDefinedSentinel(shell, 'Diplomacy');
        if (sentinel != null) return sentinel;
        final orders = shellRef.watch(currentOrdersProvider);
        MapTopology topology = const MapTopology();
        try {
          final gameService = shellRef.watch(gameServiceProvider);
          final loaded = gameService.getMapData(displayGame.id);
          if (loaded != null) {
            topology = loaded.combinedTopology;
          }
        } on Object {
          // Widget tests may not initialize Hive-backed game service providers.
        }
        final readOnly = !shell.canMutateViaUi;
        return GrantOrSubsidyListener(
          bus: bus,
          game: displayGame,
          humanPlayerId: humanPlayerId,
          readOnly: readOnly,
          child: DiplomacyPanel(
            game: displayGame,
            humanPlayerId: humanPlayerId,
            topology: topology,
            currentOrders: orders,
            bus: bus,
            readOnly: readOnly,
          ),
        );
      },
    );
  }
}
