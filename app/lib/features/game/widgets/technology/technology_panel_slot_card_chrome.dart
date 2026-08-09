import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_spacing.dart';
import 'technology_panel_gradients.dart';

/// Shared slot-card chrome for active and locked research slot cards.
class TechnologyPanelSlotCardChrome extends StatelessWidget {
  const TechnologyPanelSlotCardChrome({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: technologyDarkSurfaceGradient(),
        border: Border.all(
          color: EditorialMonoclePalette.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: CtSpacing.m,
        ),
        child: child,
      ),
    );
  }
}
