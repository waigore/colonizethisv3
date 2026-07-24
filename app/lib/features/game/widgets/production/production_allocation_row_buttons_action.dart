import 'package:flutter/material.dart';

import '../../../../config/app_assets.dart';
import 'production_allocation_row_buttons.dart';
import 'production_allocation_row_buttons_surface.dart';

/// Single tap (maximize / clear) icon control.
class ProductionAllocationActionIconButton extends StatelessWidget {
  const ProductionAllocationActionIconButton({
    super.key,
    required this.enabled,
    required this.readDesired,
    required this.onPressedFromCurrent,
    required this.semanticLabel,
    required this.tooltip,
    required this.assetFileName,
    this.iconSize = 15,
  });

  final bool enabled;
  final ProductionDesiredMapReader readDesired;
  final void Function(Map<String, int> current) onPressedFromCurrent;
  final String semanticLabel;
  final String tooltip;
  final String assetFileName;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final path = '$kAppIconAssetPrefix$assetFileName';
    final surface = ProductionStepButtonSurface(
      enabled: enabled,
      iconAssetPath: path,
      iconSize: iconSize,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => onPressedFromCurrent(readDesired()) : null,
            child: surface,
          ),
        ),
      ),
    );
  }
}
