import 'package:flutter/material.dart';

import 'game_screen_shared.dart';

/// Top-left corner buttons for the in-game map.
class GameMapCornerControls extends StatelessWidget {
  const GameMapCornerControls({
    required this.onCycleBaseLayerDisplayMode,
    required this.onCenterOnHomeCapital,
    required this.onOpenMapDisplayOptions,
    super.key,
  });

  final VoidCallback onCycleBaseLayerDisplayMode;
  final VoidCallback onCenterOnHomeCapital;
  final VoidCallback onOpenMapDisplayOptions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          key: kBaseLayerCycleButtonKey,
          color: Colors.white.withValues(alpha: 0.9),
          child: Tooltip(
            message: 'Base layer: terrain / +resources / +improvements',
            child: InkWell(
              onTap: onCycleBaseLayerDisplayMode,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/images/ui_icon_layer_toggle.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Material(
          key: kHomeToCapitalButtonKey,
          color: Colors.white.withValues(alpha: 0.9),
          child: Tooltip(
            message: 'Center on capital',
            child: InkWell(
              onTap: onCenterOnHomeCapital,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/images/ui_icon_home_capital.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Material(
          key: kMapDisplayOptionsButtonKey,
          color: Colors.white.withValues(alpha: 0.9),
          child: Tooltip(
            message: 'Map display options',
            child: InkWell(
              onTap: onOpenMapDisplayOptions,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  'Map options',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

