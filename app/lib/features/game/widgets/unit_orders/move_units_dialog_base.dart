// Shared scaffold + destination-row chrome for the in-game move dialogs.
//
// SPEC/ui/components/move-units-dialog-base.md.
// Consumed by SPEC/ui/move-army-dialog.md (`MoveArmyDialog`) and
// SPEC/ui/move-fleet-dialog.md (`MoveFleetDialog`): both render a
// `CtDialogShell` body of [title, CtSectionLabel-headed destination
// groups, trailing Cancel/Confirm Wrap] over the same 1 px/2 px
// `--border`/`--accent` radio-row outline contract (#2867 R1/R7).
//
// De-parted wave-9 cluster (Refs #4117): thin re-export façade over
// explicit-import libraries.

export 'move_units_dialog_base_row.dart'
    show MoveDialogDestinationRow, MoveDialogRadioDot;
export 'move_units_dialog_base_scaffold.dart' show MoveUnitsDialogState;
export 'move_units_dialog_base_styles.dart'
    show
        moveDialogEmptyTextStyle,
        moveDialogRowLabelStyle,
        moveDialogTitleTextStyle;
