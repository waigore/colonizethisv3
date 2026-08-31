// Full-screen Counsel screen. SPEC/ui/counsel-panel.md (Refs #4190 / #4191 / #4282 / #4307).

export 'counsel_screen_tabs.dart' show CounselTab, counselTabFromRouteArg;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_constants.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../core/services/game_service/try_get_game_map_data.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../widgets/ct_app_perf_interactive_ready_marker.dart';
import '../../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../../widgets/game_feature_screen_top_bar.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../../widgets/shell/shell_player_guarded_body.dart';
import 'counsel_panel_map_context.dart';
import 'counsel_screen_tabs.dart';

class CounselScreen extends ConsumerWidget {
  const CounselScreen({
    super.key,
    required this.game,
    required this.humanPlayerId,
    this.highlightRecommendationId,
    this.initialTab = CounselTab.industry,
  });

  /// SPEC/ui/counsel-panel.md — [UiScreenIds.counselScreen].
  static const screenId = UiScreenIds.counselScreen;

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarTitle = 'Counsel';

  static const String topBarIconAsset =
      '${kAppIconAssetPrefix}ui_icon_production.png';

  final Game game;
  final String humanPlayerId;
  final String? highlightRecommendationId;
  final CounselTab initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CtGameFeatureScreenShell(
      game: game,
      topBar: GameFeatureScreenTopBar.build(
        key: const ValueKey<String>('counselScreenTopBar'),
        title: topBarTitle,
        iconAsset: topBarIconAsset,
      ),
      bodyBuilder: (context, shellRef, displayGame) {
        final shell = shellRef.read(shellPlayerContextProvider);
        final sentinel = observeNotDefinedSentinel(shell, 'Counsel');
        if (sentinel != null) return sentinel;
        final canEdit = shell.canMutateViaUi;
        final l10n = appL10n(context);
        final mapContext = counselPanelMapContextFromLoaded(
          tryGetGameMapData(
            () => shellRef.watch(gameServiceProvider).getMapData(displayGame.id),
          ),
        );
        return CtAppPerfInteractiveReadyMarker(
          markerName: 'counsel.interactiveReady',
          child: CounselScreenTabs(
            initialTab: initialTab,
            l10n: l10n,
            displayGame: displayGame,
            humanPlayerId: humanPlayerId,
            mapContext: mapContext,
            highlightRecommendationId: highlightRecommendationId,
            canEdit: canEdit,
          ),
        );
      },
    );
  }
}
