// Full-screen Technology view with Slots and Tree tabs. SPEC/ui/technology-panel.md.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../providers/games_provider.dart';
import '../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/ct_top_bar.dart';
import '../../../widgets/strict_asset_icon.dart';
import '../shell_player_context.dart';
import '../widgets/observe_mode_not_defined_panel.dart';
import '../widgets/tech_tree_widget.dart';
import '../widgets/technology_panel.dart';

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
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarBackLabel = 'Map';

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

enum _TechnologyTab { slots, tree }

class _TechnologyScreenState extends ConsumerState<TechnologyScreen> {
  _TechnologyTab _tab = _TechnologyTab.slots;

  void _select(_TechnologyTab next) {
    if (_tab == next) return;
    setState(() => _tab = next);
  }

  @override
  Widget build(BuildContext context) {
    final currentOrders = ref.watch(currentOrdersProvider);
    return CtGameFeatureScreenShell(
      game: widget.game,
      topBar: CtTopBar(
        key: TechnologyScreen.topBarKey,
        title: TechnologyScreen.topBarTitle,
        backButtonLabel: TechnologyScreen.topBarBackLabel,
        icon: const StrictAssetIcon(
          assetPath: TechnologyScreen.topBarIconAsset,
          width: 18,
          height: 18,
        ),
        trailing: _TechnologyTabToggle(
          selected: _tab,
          onSelect: _select,
        ),
      ),
      bodyBuilder: (context, shellRef, displayGame) {
        if (shellPanelsNotDefined(shellRef)) {
          // ignore: avoid_hardcoded_strings_in_widgets
          return const ObserveModeNotDefinedPanel(title: 'Technology');
        }
        final displayPlayer = displayGame.playerById(widget.player.id)!;
        final canEdit = shellRef
            .read(shellPlayerContextProvider)
            .canMutateViaUi;
        switch (_tab) {
          case _TechnologyTab.slots:
            return _SlotsBody(
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
          case _TechnologyTab.tree:
            return _TreeBody(game: displayGame, player: displayPlayer);
        }
      },
    );
  }
}

/// Slots / Tree toggle for the trailing slot of the technology top bar.
///
/// Implements the mockup `.tab-row` rule with two non-Material chip buttons
/// painted in the dark editorial-monocle palette. Selected chip uses
/// `--accent` border + accent-tinted background; unselected uses `--border`
/// + transparent background. No Material `Chip` / `ChoiceChip` /
/// `ToggleButtons` per the catalog ban.
class _TechnologyTabToggle extends StatelessWidget {
  const _TechnologyTabToggle({required this.selected, required this.onSelect});

  final _TechnologyTab selected;
  final void Function(_TechnologyTab next) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _TechnologyTabChip(
          key: TechnologyScreen.slotsToggleKey,
          // ignore: avoid_hardcoded_strings_in_widgets
          label: 'Slots',
          selected: selected == _TechnologyTab.slots,
          onTap: () => onSelect(_TechnologyTab.slots),
        ),
        const SizedBox(width: 6),
        _TechnologyTabChip(
          key: TechnologyScreen.treeToggleKey,
          // ignore: avoid_hardcoded_strings_in_widgets
          label: 'Tree',
          selected: selected == _TechnologyTab.tree,
          onTap: () => onSelect(_TechnologyTab.tree),
        ),
      ],
    );
  }
}

class _TechnologyTabChip extends StatelessWidget {
  const _TechnologyTabChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _verticalPadding = 4;
  static const double _horizontalPadding = 10;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle base =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final Color borderColor = selected
        ? EditorialMonoclePalette.accent
        : EditorialMonoclePalette.border;
    final Color labelColor = selected
        ? EditorialMonoclePalette.accentBright
        : EditorialMonoclePalette.muted;
    final Color backgroundColor = selected
        ? EditorialMonoclePalette.accent.withValues(alpha: 0.18)
        : Colors.transparent;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: _horizontalPadding,
              vertical: _verticalPadding,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Text(
              label,
              style: base.copyWith(
                color: labelColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.04,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotsBody extends StatelessWidget {
  const _SlotsBody({
    required this.game,
    required this.player,
    this.currentOrders = const Orders(),
    this.onOrdersChanged,
  });

  final Game game;
  final Player player;
  final Orders currentOrders;
  final void Function(Orders orders)? onOrdersChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: TechnologyPanel(
        game: game,
        player: player,
        currentOrders: currentOrders,
        onOrdersChanged: onOrdersChanged,
      ),
    );
  }
}

class _TreeBody extends StatelessWidget {
  const _TreeBody({required this.game, required this.player});

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context) {
    return TechTreeWidget(game: game, player: player);
  }
}
