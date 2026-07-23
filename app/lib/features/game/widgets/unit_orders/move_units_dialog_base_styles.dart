part of 'move_units_dialog_base.dart';

/// Title text style shared by the move dialogs — dark-theme `titleMedium`
/// in `--accent` with 0.05em letter spacing (#2867 R2/R5).
TextStyle moveDialogTitleTextStyle(ThemeData theme) {
  return (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16)).copyWith(
    color: EditorialMonoclePalette.accent,
    letterSpacing: 0.05 * 16,
    fontWeight: FontWeight.w600,
  );
}

/// Empty-state body style shared by the move dialogs (`--muted` body).
TextStyle moveDialogEmptyTextStyle(ThemeData theme) {
  return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
    color: EditorialMonoclePalette.muted,
  );
}

/// Destination-row title style shared by the move dialogs. Selected rows
/// render at full `--fg`; idle rows at 90% `--fg` opacity (#2867 R7).
TextStyle moveDialogRowLabelStyle(ThemeData theme, {required bool selected}) {
  return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
    color: selected
        ? EditorialMonoclePalette.fg
        : EditorialMonoclePalette.fg.withValues(alpha: 0.9),
  );
}
