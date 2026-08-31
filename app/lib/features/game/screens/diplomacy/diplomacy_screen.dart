// Full-screen Diplomacy screen. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_constants.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../core/services/game_service/try_get_game_map_data.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/diplomacy_panel_session_cache_provider.dart';
import '../../../../widgets/ct_action_text_button.dart';
import '../../../../widgets/ct_app_perf_interactive_ready_marker.dart';
import '../../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/game_feature_screen_top_bar.dart';
import '../../widgets/shell/shell_player_context.dart'
    show shellPlayerContextProvider;
import '../../widgets/shell/shell_player_guarded_body.dart';
import '../../widgets/diplomacy/diplomacy_panel.dart';
import '../../widgets/diplomacy/grant_or_subsidy_listener.dart';
import 'intelligence_council_screen.dart';

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
  static const String topBarBackLabel = GameFeatureScreenTopBar.backLabel;

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
    final l10n = appL10n(context);
    final intelCount =
        game.lastTurnIntelligenceDigest?.lineCountForObserver(humanPlayerId) ??
        0;
    return CtGameFeatureScreenShell(
      game: game,
      topBar: GameFeatureScreenTopBar.build(
        key: topBarKey,
        title: topBarTitle,
        iconAsset: topBarIconAsset,
        trailing: DiplomacyIntelligenceTrailing(
          label: l10n.diplomacy_intelligence,
          count: intelCount,
          onPressed: () => emitOpenIntelligenceCouncil(
            bus: bus,
            game: game,
            humanPlayerId: humanPlayerId,
          ),
        ),
      ),
      bodyBuilder: (context, shellRef, displayGame) {
        final shell = shellRef.read(shellPlayerContextProvider);
        final sentinel = observeNotDefinedSentinel(shell, 'Diplomacy');
        if (sentinel != null) return sentinel;
        final orders = shellRef.watch(currentOrdersProvider);
        MapTopology topology = const MapTopology();
        final loaded = tryGetGameMapData(
          () => shellRef.watch(gameServiceProvider).getMapData(displayGame.id),
        );
        if (loaded != null) {
          topology = loaded.combinedTopology;
        }
        final readOnly = !shell.canMutateViaUi;
        final rows = shellRef.watch(diplomacyPanelRowsProvider);
        if (rows == null) {
          return const SizedBox.shrink();
        }
        return CtAppPerfInteractiveReadyMarker(
          markerName: 'diplomacy.interactiveReady',
          surfaceOpenId: 'diplomacy',
          child: GrantOrSubsidyListener(
            bus: bus,
            game: displayGame,
            humanPlayerId: humanPlayerId,
            readOnly: readOnly,
            child: DiplomacyPanel(
              game: displayGame,
              humanPlayerId: humanPlayerId,
              topology: topology,
              currentOrders: orders,
              rows: rows,
              bus: bus,
              readOnly: readOnly,
            ),
          ),
        );
      },
    );
  }
}

class DiplomacyIntelligenceTrailing extends StatelessWidget {
  const DiplomacyIntelligenceTrailing({
    super.key,
    required this.label,
    required this.count,
    required this.onPressed,
  });

  static const Key buttonKey = ValueKey<String>(
    'diplomacy_intelligence_button',
  );

  final String label;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(right: CtSpacing.s),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: EditorialMonoclePalette.accent,
              ),
            ),
          ),
        CtActionTextButton(key: buttonKey, onPressed: onPressed, label: label),
      ],
    );
  }
}
