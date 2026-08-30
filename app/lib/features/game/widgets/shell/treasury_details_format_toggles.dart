import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';

class TreasuryFormatToggles extends StatelessWidget {
  const TreasuryFormatToggles({
    super.key,
    required this.l10n,
    required this.showExact,
    required this.onShowExactChanged,
    required this.exactFormatKey,
    required this.compactFormatKey,
  });

  final AppLocalizations l10n;
  final bool showExact;
  final ValueChanged<bool> onShowExactChanged;
  final Key exactFormatKey;
  final Key compactFormatKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        TreasuryFormatToggle(
          key: exactFormatKey,
          label: l10n.mapControls_treasury_details_formatExact,
          selected: showExact,
          onTap: () => onShowExactChanged(true),
        ),
        const SizedBox(width: CtSpacing.s),
        TreasuryFormatToggle(
          key: compactFormatKey,
          label: l10n.mapControls_treasury_details_formatCompact,
          selected: !showExact,
          onTap: () => onShowExactChanged(false),
        ),
      ],
    );
  }
}

class TreasuryFormatToggle extends StatelessWidget {
  const TreasuryFormatToggle({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? EditorialMonoclePalette.bg
              : EditorialMonoclePalette.surface,
          border: Border.all(
            color: selected
                ? EditorialMonoclePalette.accent
                : EditorialMonoclePalette.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? EditorialMonoclePalette.accent
                  : EditorialMonoclePalette.muted,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
