// Bottom filter mode bar for DiplomacyPanel. SPEC/ui/diplomacy-panel.md
// § Mode bar (filter).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_gradients.dart';
import '../../../../widgets/ct_radius.dart';
import '../../../../widgets/ct_spacing.dart';
import 'diplomacy_panel_rows.dart';

/// Bottom mode-bar filter for the Diplomacy panel.
///
/// SPEC/ui/diplomacy-panel.md § Mode bar (filter): anchored to the bottom of
/// the panel with a `--border` top divider; buttons use mono font with
/// inactive label `--muted`, active label `--accent`, and `--accent-dim`
/// border on the active item.
class DiplomacyModeBar extends StatelessWidget {
  const DiplomacyModeBar({super.key, required this.mode, required this.onModeChanged});

  final DiplomacyFilterMode mode;
  final ValueChanged<DiplomacyFilterMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: EditorialMonoclePalette.border, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CtSpacing.ml,
          vertical: CtSpacing.m,
        ),
        // SPEC/ui/mobile-adaptation.md § 7 Minimum-viewport pin: the three
        // filter labels ("All", "Great Powers only", "Minors only") total
        // ~458 dp intrinsic width but the panel body is only ~296 dp wide
        // at `kMinViewportWidth` (320 dp) once the ListView horizontal
        // padding is subtracted. A centered `Row` overflows by ~162 px on
        // the right at that width. `Wrap` keeps the mockup's centred
        // cluster at wide widths (all three chips fit on one run) and lets
        // the buttons flow onto a second run at the minimum viewport
        // without clipping or horizontal scroll.
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            DiplomacyModeButton(
              label: l10n.diplomacy_filter_all,
              isActive: mode == DiplomacyFilterMode.all,
              onPressed: () => onModeChanged(DiplomacyFilterMode.all),
            ),
            DiplomacyModeButton(
              label: l10n.diplomacy_filter_greatPowersOnly,
              isActive: mode == DiplomacyFilterMode.greatPowersOnly,
              onPressed: () =>
                  onModeChanged(DiplomacyFilterMode.greatPowersOnly),
            ),
            DiplomacyModeButton(
              label: l10n.diplomacy_filter_minorsOnly,
              isActive: mode == DiplomacyFilterMode.minorsOnly,
              onPressed: () => onModeChanged(DiplomacyFilterMode.minorsOnly),
            ),
          ],
        ),
      ),
    );
  }
}

class DiplomacyModeButton extends StatelessWidget {
  const DiplomacyModeButton({super.key, 
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color labelColor = isActive
        ? EditorialMonoclePalette.accent
        : EditorialMonoclePalette.muted;
    // SPEC/ui/diplomacy-panel.md § Mode-bar chip chrome (Refs #3621): the
    // mockup `.mode-bar button` paints the compact action gradient
    // (`--surface-lite → --bg-deep`) with a 1 px border in every state —
    // `--border` when inactive, `--accent-dim` when active. The earlier
    // implementation drew no border on the inactive chip.
    final Color borderColor = isActive
        ? EditorialMonoclePalette.accentDim
        : EditorialMonoclePalette.border;
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: CtGradients.actionButtonGradient,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(CtRadius.small),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Courier'],
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
