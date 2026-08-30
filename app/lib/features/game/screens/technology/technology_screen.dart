// Full-screen Technology view with Slots and Tree tabs. SPEC/ui/technology-panel.md.


import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_constants.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../providers/games_provider.dart';
import '../../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../../widgets/game_feature_screen_top_bar.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../../widgets/shell/shell_player_guarded_body.dart';
import 'technology_screen_body.dart';
import 'technology_screen_tab.dart';
import 'technology_screen_top_bar.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_logic/ai_api.dart';

/// Full-screen Technology screen with two tabs: Research Slots and Tech Tree.
///
/// Dark editorial-monocle chrome per `SPEC/ui/technology-panel.md` § Top bar:
/// the `CtTopBar` carries the `Map` back affordance, the 18 × 18 pixel-art
/// technology icon, and a `CtChoiceChip` Slots / Tree toggle in the trailing
/// slot. The body switches between [TechnologyPanel] (Slots) and
/// [TechTreeWidget] (Tree) based on the locally held tab state. Material
/// `TabBar` / `Tab` / `Divider` / `AppBar` are forbidden on this surface per
/// `SPEC/ui/pixel-art-ui-catalog.md` Material ban (#2864 S1).
class TechnologyScreen extends ConsumerStatefulWidget {
  const TechnologyScreen({super.key, required this.game, required this.player});

  /// SPEC/ui/technology-panel.md — [UiScreenIds.technologyScreen].
  static const screenId = UiScreenIds.technologyScreen;

  /// Localized back-button label rendered immediately after the chevron on
  /// the dark-theme `CtTopBar`. SPEC requires the literal `"Map"` so the
  /// affordance reads `"← Map"`.
  static const String topBarBackLabel = GameFeatureScreenTopBar.backLabel;

  /// Title text shown in the dark-theme `CtTopBar`. SPEC mandates the
  /// literal `"Technology"` (Cinzel display font is configured at the
  /// theme level).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarTitle = 'Technology';

  /// Pixel-art icon asset rendered between the back affordance and the
  /// title (SPEC § Top bar — 18 × 18 px technology icon).
  static const String topBarIconAsset =
      '${kAppIconAssetPrefix}ui_icon_technology.png';

  /// Stable widget key for the technology top bar — lets widget tests pin
  /// the dark-theme chrome without coupling to localized strings.
  static const Key topBarKey = ValueKey<String>('technologyScreenTopBar');

  /// Stable key on the Slots toggle in the top-bar trailing slot.
  static const Key slotsToggleKey =
      ValueKey<String>('technologyScreenSlotsToggle');

  /// Stable key on the Tree toggle in the top-bar trailing slot.
  static const Key treeToggleKey =
      ValueKey<String>('technologyScreenTreeToggle');

  final Game game;
  final Player player;

  @override
  ConsumerState<TechnologyScreen> createState() => _TechnologyScreenState();
}

class _TechnologyScreenState extends ConsumerState<TechnologyScreen> {
  TechnologyScreenTab _tab = TechnologyScreenTab.slots;

  void _select(TechnologyScreenTab next) {
    if (_tab == next) return;
    setState(() => _tab = next);
  }

  @override
  Widget build(BuildContext context) {
    final currentOrders = ref.watch(currentOrdersProvider);
    return CtGameFeatureScreenShell(
      game: widget.game,
      topBar: GameFeatureScreenTopBar.build(
        key: TechnologyScreen.topBarKey,
        title: TechnologyScreen.topBarTitle,
        iconAsset: TechnologyScreen.topBarIconAsset,
        trailing: TechnologyTabToggle(
          selected: _tab,
          onSelect: _select,
        ),
      ),
      bodyBuilder: (context, shellRef, displayGame) {
        final shell = shellRef.read(shellPlayerContextProvider);
        // ignore: avoid_hardcoded_strings_in_widgets
        final sentinel = observeNotDefinedSentinel(shell, 'Technology');
        if (sentinel != null) return sentinel;
        final displayPlayer = displayGame.playerById(widget.player.id)!;
        final canEdit = shell.canMutateViaUi;
        switch (_tab) {
          case TechnologyScreenTab.slots:
            return TechnologySlotsBody(
              game: displayGame,
              player: displayPlayer,
              currentOrders: currentOrders,
              onOrdersChanged: canEdit
                  ? (next) {
                      shellRef
                          .read(currentOrdersProvider.notifier)
                          .replaceAll(next);
                    }
                  : null,
            );
          case TechnologyScreenTab.tree:
            return TechnologyTreeBody(
              game: displayGame,
              player: displayPlayer,
              currentOrders: currentOrders,
              onOrdersChanged: canEdit
                  ? (next) {
                      shellRef
                          .read(currentOrdersProvider.notifier)
                          .replaceAll(next);
                    }
                  : null,
            );
        }
      },
    );
  }
}
