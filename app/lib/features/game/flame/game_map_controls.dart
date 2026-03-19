import 'package:flutter/material.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import '../../../widgets/ct_choice_chip.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// Top bar and region chips for the in-game map shell.
class GameMapControls extends StatelessWidget {
  const GameMapControls({
    required this.sideMenuOpen,
    required this.onToggleSideMenu,
    required this.onNextTurn,
    required this.regionIndex,
    required this.onRegionIndexChanged,
    required this.nextTurnText,
    super.key,
  });

  final bool sideMenuOpen;
  final VoidCallback onToggleSideMenu;
  final Future<void> Function() onNextTurn;
  final int regionIndex;
  final void Function(int index) onRegionIndexChanged;
  final String nextTurnText;

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
            ],
          ),
        ),
      ],
    );
  }
}

