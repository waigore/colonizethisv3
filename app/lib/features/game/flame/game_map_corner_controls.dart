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
        _MapCornerIconButton(
          key: kBaseLayerCycleButtonKey,
          tooltip: l10n.mapCorner_tooltipBaseLayer,
          onTap: onCycleBaseLayerDisplayMode,
          assetPath: '${kAppIconAssetPrefix}ui_icon_layer_toggle.png',
        ),
        const SizedBox(width: 4),
        _MapCornerIconButton(
          key: kHomeToCapitalButtonKey,
          tooltip: l10n.mapCorner_tooltipCenterCapital,
          onTap: onCenterOnHomeCapital,
          assetPath: '${kAppIconAssetPrefix}ui_icon_home_capital.png',
        ),
        const SizedBox(width: 4),
        _MapCornerIconButton(
          key: kMapDisplayOptionsButtonKey,
          tooltip: l10n.mapCorner_tooltipMapDisplayOptions,
          onTap: onOpenMapDisplayOptions,
          assetPath: '${kAppIconAssetPrefix}ui_icon_map_options.png',
        ),
      ],
    );
  }
}

class _MapCornerIconButton extends StatelessWidget {
  const _MapCornerIconButton({
    super.key,
    required this.tooltip,
    required this.onTap,
    required this.assetPath,
  });

  final String tooltip;
  final VoidCallback onTap;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: StrictAssetIcon(assetPath: assetPath, width: 20, height: 20),
          ),
        ),
      ),
    );
  }
}
