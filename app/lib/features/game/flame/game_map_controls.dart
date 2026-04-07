import 'package:flutter/material.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import '../../../config/app_assets.dart';
import '../../../widgets/ct_choice_chip.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/strict_asset_icon.dart';
import 'game_screen_shared.dart';

/// Top bar and region chips for the in-game map shell.
class GameMapControls extends StatelessWidget {
  const GameMapControls({
    required this.sideMenuOpen,
    required this.onToggleSideMenu,
    required this.onNextTurn,
    required this.regionIndex,
    required this.onRegionIndexChanged,
    required this.nextTurnText,
    required this.cargoUsed,
    required this.cargoCapacity,
    this.isCargoUsedReliable = true,
    super.key,
  });

  final bool sideMenuOpen;
  final VoidCallback onToggleSideMenu;
  final Future<void> Function() onNextTurn;
  final int regionIndex;
  final void Function(int index) onRegionIndexChanged;
  final String nextTurnText;
  final int cargoUsed;
  final int cargoCapacity;
  final bool isCargoUsedReliable;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onToggleSideMenu,
                tooltip: l10n.gameMap_menuTooltip,
              ),
              Expanded(
                child: CtNinePatchButton(
                  onPressed: () => onNextTurn(),
                  child: Text(nextTurnText),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CtChoiceChip(
                label: Text(l10n.region_oldWorld),
                selected: regionIndex == 0,
                onSelected: (_) => onRegionIndexChanged(0),
              ),
              const SizedBox(width: 8),
              CtChoiceChip(
                label: Text(l10n.region_newWorld),
                selected: regionIndex == 1,
                onSelected: (_) => onRegionIndexChanged(1),
              ),
              const SizedBox(width: 10),
              Container(
                key: kCargoHoldIndicatorKey,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: Colors.black.withValues(alpha: 0.1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const StrictAssetIcon(
                      assetPath: '${kAppIconAssetPrefix}ui_icon_cargo_hold.png',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isCargoUsedReliable ? '$cargoUsed' : '—'}/$cargoCapacity',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
