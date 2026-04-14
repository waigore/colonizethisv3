import 'package:flutter/material.dart';

import '../../../config/app_assets.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/strict_asset_icon.dart';
import 'game_screen_shared.dart';

/// Bottom-left horizontal row: map tool buttons for the in-game map.
/// SPEC/ui/empire-overview.md § Base layer display cycle, Home-to-capital, Map display options.
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
    final l10n = appL10n(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          key: kBaseLayerCycleButtonKey,
          color: Colors.white.withValues(alpha: 0.9),
          child: Tooltip(
            message: l10n.mapCorner_tooltipBaseLayer,
            child: InkWell(
              onTap: onCycleBaseLayerDisplayMode,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: StrictAssetIcon(
                  assetPath: '${kAppIconAssetPrefix}ui_icon_layer_toggle.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Material(
          key: kHomeToCapitalButtonKey,
          color: Colors.white.withValues(alpha: 0.9),
          child: Tooltip(
            message: l10n.mapCorner_tooltipCenterCapital,
            child: InkWell(
              onTap: onCenterOnHomeCapital,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: StrictAssetIcon(
                  assetPath: '${kAppIconAssetPrefix}ui_icon_home_capital.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Material(
          key: kMapDisplayOptionsButtonKey,
          color: Colors.white.withValues(alpha: 0.9),
          child: Tooltip(
            message: l10n.mapCorner_tooltipMapDisplayOptions,
            child: InkWell(
              onTap: onOpenMapDisplayOptions,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: StrictAssetIcon(
                  assetPath: '${kAppIconAssetPrefix}ui_icon_map_options.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
