// Bottom filter mode bar for DiplomacyPanel. SPEC/ui/diplomacy-panel.md
// § Mode bar (filter).

part of 'diplomacy_panel.dart';

/// Bottom mode-bar filter for the Diplomacy panel.
///
/// SPEC/ui/diplomacy-panel.md § Mode bar (filter): anchored to the bottom of
/// the panel with a `--border` top divider; buttons use mono font with
/// inactive label `--muted`, active label `--accent`, and `--accent-dim`
/// border on the active item.
class _DiplomacyModeBar extends StatelessWidget {
  const _DiplomacyModeBar({required this.mode, required this.onModeChanged});

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _DiplomacyModeButton(
              label: l10n.diplomacy_filter_all,
              isActive: mode == DiplomacyFilterMode.all,
              onPressed: () => onModeChanged(DiplomacyFilterMode.all),
            ),
            const SizedBox(width: 8),
            _DiplomacyModeButton(
              label: l10n.diplomacy_filter_greatPowersOnly,
              isActive: mode == DiplomacyFilterMode.greatPowersOnly,
              onPressed: () =>
                  onModeChanged(DiplomacyFilterMode.greatPowersOnly),
            ),
            const SizedBox(width: 8),
            _DiplomacyModeButton(
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

class _DiplomacyModeButton extends StatelessWidget {
  const _DiplomacyModeButton({
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
    final Border? border = isActive
        ? Border.all(color: EditorialMonoclePalette.accentDim, width: 1)
        : null;
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: border,
          borderRadius: BorderRadius.circular(2),
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
