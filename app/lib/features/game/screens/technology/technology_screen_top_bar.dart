// Slots / Tree top-bar toggle chrome for [TechnologyScreen].

part of 'technology_screen.dart';

enum _TechnologyTab { slots, tree }

/// Slots / Tree toggle for the trailing slot of the technology top bar.
///
/// Implements the mockup `.tab-row` rule with two non-Material chip buttons
/// painted in the dark editorial-monocle palette. Selected chip uses
/// `--accent` border + accent-tinted background; unselected uses `--border`
/// + transparent background. No Material `Chip` / `ChoiceChip` /
/// `ToggleButtons` per the catalog ban.
class _TechnologyTabToggle extends StatelessWidget {
  const _TechnologyTabToggle({required this.selected, required this.onSelect});

  final _TechnologyTab selected;
  final void Function(_TechnologyTab next) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _TechnologyTabChip(
          key: TechnologyScreen.slotsToggleKey,
          // ignore: avoid_hardcoded_strings_in_widgets
          label: 'Slots',
          selected: selected == _TechnologyTab.slots,
          onTap: () => onSelect(_TechnologyTab.slots),
        ),
        const SizedBox(width: 6),
        _TechnologyTabChip(
          key: TechnologyScreen.treeToggleKey,
          // ignore: avoid_hardcoded_strings_in_widgets
          label: 'Tree',
          selected: selected == _TechnologyTab.tree,
          onTap: () => onSelect(_TechnologyTab.tree),
        ),
      ],
    );
  }
}

class _TechnologyTabChip extends StatelessWidget {
  const _TechnologyTabChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _verticalPadding = 4;
  static const double _horizontalPadding = 10;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle base =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final Color borderColor = selected
        ? EditorialMonoclePalette.accent
        : EditorialMonoclePalette.border;
    final Color labelColor = selected
        ? EditorialMonoclePalette.accentBright
        : EditorialMonoclePalette.muted;
    final Color backgroundColor = selected
        ? EditorialMonoclePalette.accent.withValues(alpha: 0.18)
        : Colors.transparent;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: _horizontalPadding,
              vertical: _verticalPadding,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Text(
              label,
              style: base.copyWith(
                color: labelColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.04,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
