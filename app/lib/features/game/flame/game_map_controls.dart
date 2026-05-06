import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import '../../../config/app_assets.dart';
import '../../../config/ct_e2e.dart';
import '../../../widgets/ct_choice_chip.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/strict_asset_icon.dart';
import '../widgets/player_turn_event_feed.dart';
import 'game_screen_shared.dart'
    show
        kCargoHoldIndicatorKey,
        kGameMapNextTurnButtonKey,
        kTreasuryIndicatorKey;

/// Top bar and region chips for the in-game map shell.
class GameMapControls extends StatefulWidget {
  const GameMapControls({
    required this.sideMenuOpen,
    required this.onToggleSideMenu,
    required this.onNextTurn,
    required this.nextTurnEnabled,
    required this.regionIndex,
    required this.onRegionIndexChanged,
    required this.nextTurnText,
    required this.cargoUsed,
    required this.cargoCapacity,
    required this.treasury,
    required this.treasuryDelta,
    required this.playerTurnEventsFeedCount,
    required this.showPlayerTurnEventsFeed,
    required this.onTogglePlayerTurnEventsFeed,
    this.isCargoUsedReliable = true,
    super.key,
  });

  final bool sideMenuOpen;
  final VoidCallback onToggleSideMenu;
  final Future<void> Function() onNextTurn;
  final bool nextTurnEnabled;
  final int regionIndex;
  final void Function(int index) onRegionIndexChanged;
  final String nextTurnText;
  final int cargoUsed;
  final int cargoCapacity;
  final int treasury;
  final int? treasuryDelta;
  final int playerTurnEventsFeedCount;
  final bool showPlayerTurnEventsFeed;
  final VoidCallback onTogglePlayerTurnEventsFeed;
  final bool isCargoUsedReliable;

  @override
  State<GameMapControls> createState() => _GameMapControlsState();
}

class _GameMapControlsState extends State<GameMapControls> {
  static final NumberFormat _exactTreasuryFormat =
      NumberFormat.decimalPattern();
  static final NumberFormat _abbrevTreasuryFormat = NumberFormat.compact(
    locale: 'en_US',
  );
  bool _showExactTreasury = true;

  String _formatTreasury(int value) {
    if (_showExactTreasury) {
      return _exactTreasuryFormat.format(value);
    }
    final compactRaw = _abbrevTreasuryFormat.format(value);
    final compact = compactRaw.replaceAll('K', 'k');
    if (compact.contains('.') || !compact.endsWith('k')) {
      return compact;
    }
    return compact.replaceFirst('k', '.0k');
  }

  Color? _treasuryDeltaColor(int? delta) {
    if (delta == null || delta == 0) {
      return null;
    }
    return delta > 0 ? Colors.green : Colors.red;
  }

  String? _treasuryDeltaLabel(int? delta) {
    if (delta == null || delta == 0) {
      return null;
    }
    if (delta > 0) {
      return '+$delta';
    }
    return '$delta';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final treasuryLabel = _formatTreasury(widget.treasury);
    final deltaLabel = _treasuryDeltaLabel(widget.treasuryDelta);
    final deltaColor = _treasuryDeltaColor(widget.treasuryDelta);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: widget.onToggleSideMenu,
                tooltip: l10n.gameMap_menuTooltip,
              ),
              Expanded(
                child: CtNinePatchButton(
                  key: kGameMapNextTurnButtonKey,
                  onPressed: widget.nextTurnEnabled
                      ? () => widget.onNextTurn()
                      : null,
                  child: Text(widget.nextTurnText),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CtChoiceChip(
                              label: Text(l10n.region_oldWorld),
                              selected: widget.regionIndex == 0,
                              onSelected: (_) => widget.onRegionIndexChanged(0),
                            ),
                            const SizedBox(width: 8),
                            // E2E-only wrapper: same layout as bare chip; adds a stable subtree key
                            // for integration tests (`kCtE2ERegionTabNewWorldKey`).
                            if (kCtE2EEnabled)
                              KeyedSubtree(
                                key: kCtE2ERegionTabNewWorldKey,
                                child: CtChoiceChip(
                                  label: Text(l10n.region_newWorld),
                                  selected: widget.regionIndex == 1,
                                  onSelected: (_) =>
                                      widget.onRegionIndexChanged(1),
                                ),
                              )
                            else
                              CtChoiceChip(
                                label: Text(l10n.region_newWorld),
                                selected: widget.regionIndex == 1,
                                onSelected: (_) =>
                                    widget.onRegionIndexChanged(1),
                              ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              key: kTreasuryIndicatorKey,
                              onTap: () => setState(
                                () => _showExactTreasury = !_showExactTreasury,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                color: Colors.black.withValues(alpha: 0.1),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const StrictAssetIcon(
                                      assetPath:
                                          '${kAppIconAssetPrefix}ui_icon_treasury_coin.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(treasuryLabel),
                                    if (deltaLabel != null) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        deltaLabel,
                                        style: TextStyle(color: deltaColor),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              key: kCargoHoldIndicatorKey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              color: Colors.black.withValues(alpha: 0.1),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const StrictAssetIcon(
                                    assetPath:
                                        '${kAppIconAssetPrefix}ui_icon_cargo_hold.png',
                                    width: 16,
                                    height: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.mapControls_cargoHold(
                                      widget.isCargoUsedReliable
                                          ? '${widget.cargoUsed}'
                                          : '—',
                                      '${widget.cargoCapacity}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              PlayerTurnEventsFeedToggleButton(
                eventCount: widget.playerTurnEventsFeedCount,
                tooltip: l10n.playerTurnFeed_eventsChip(
                  widget.playerTurnEventsFeedCount,
                ),
                showFeed: widget.showPlayerTurnEventsFeed,
                onPressed: widget.onTogglePlayerTurnEventsFeed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
