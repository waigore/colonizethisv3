part of 'new_game_leader_selection_dialog.dart';

/// Slot label chrome and shared text-style resolution for
/// [NewGameLeaderSelectionDialog] (Refs #3878 shell modularization).
mixin _NewGameLeaderSelectionDialogSlots
    on State<NewGameLeaderSelectionDialog>, _NewGameLeaderSelectionDialogStateBase {
  /// Slot heading row: `Slot N` plus a `YOU` tag for the human slot (0).
  /// Mirrors the mockup `.slot-label` / `.you-tag`: the literal copy stays
  /// `You` ([AppLocalizations.shell_leaderDialog_slotYouTag]) and uppercasing
  /// is applied here as presentation, matching the mockup's CSS
  /// `text-transform:uppercase`.
  Widget _buildSlotLabel(
    AppLocalizations l10n,
    int slotIndex,
    _LeaderDialogTextStyles styles,
  ) {
    final bool isYou = slotIndex == 0;
    final TextStyle labelStyle = styles.slotLabel.copyWith(
      color: isYou
          ? EditorialMonoclePalette.accentDim
          : EditorialMonoclePalette.muted,
      fontWeight: isYou ? FontWeight.w600 : FontWeight.normal,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.shell_leaderDialog_slotLabel(slotIndex + 1),
          style: labelStyle,
        ),
        if (isYou) ...[
          const SizedBox(width: CtSpacing.s),
          Text(
            l10n.shell_leaderDialog_slotYouTag.toUpperCase(),
            key: const ValueKey<String>('leaderSelectionDialogSlotYouTag'),
            style: styles.slotYouTag,
          ),
        ],
      ],
    );
  }

  _LeaderDialogTextStyles _resolveTextStyles(ThemeData theme) {
    final TextStyle bodySmall =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    return _LeaderDialogTextStyles(
      title: (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16))
          .copyWith(
            color: EditorialMonoclePalette.accent,
            letterSpacing: (theme.textTheme.titleMedium?.fontSize ?? 16) * 0.05,
            fontWeight: FontWeight.w600,
          ),
      intro: (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
          .copyWith(
            color: EditorialMonoclePalette.muted,
            fontStyle: FontStyle.italic,
          ),
      fieldLabel: bodySmall.copyWith(
        color: EditorialMonoclePalette.accentDim,
        fontWeight: FontWeight.w600,
      ),
      helper: bodySmall.copyWith(
        color: EditorialMonoclePalette.muted,
        fontSize: 12,
      ),
      slotLabel: bodySmall.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.48,
      ),
      slotYouTag: bodySmall.copyWith(
        fontSize: 9,
        letterSpacing: 0.54,
        color: EditorialMonoclePalette.accentDim,
        fontWeight: FontWeight.normal,
      ),
      profileInlineLabel: bodySmall.copyWith(
        fontSize: 10,
        letterSpacing: 0.4,
        color: EditorialMonoclePalette.muted,
      ),
    );
  }
}
