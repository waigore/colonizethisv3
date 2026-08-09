import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';

/// Narrow (`< kNarrowBreakpoint`) layout: Available stacked above Allocation.
class ProductionPanelNarrowLayout extends StatelessWidget {
  const ProductionPanelNarrowLayout({
    super.key,
    required this.availableSubpanel,
    required this.allocationSubpanel,
  });

  final Widget availableSubpanel;
  final Widget allocationSubpanel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          availableSubpanel,
          const SizedBox(height: 24),
          allocationSubpanel,
        ],
      ),
    );
  }
}

/// Wide (`≥ kNarrowBreakpoint`) layout: Available and Allocation side by side.
class ProductionPanelWideLayout extends StatelessWidget {
  const ProductionPanelWideLayout({
    super.key,
    required this.availableSubpanel,
    required this.allocationSubpanel,
  });

  final Widget availableSubpanel;
  final Widget allocationSubpanel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: availableSubpanel),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: allocationSubpanel),
        ],
      ),
    );
  }
}
