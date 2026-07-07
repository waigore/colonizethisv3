// Shared scaffold + destination-row chrome for the in-game move dialogs.
//
// SPEC/ui/components/move-units-dialog-base.md.
// Consumed by SPEC/ui/move-army-dialog.md (`MoveArmyDialog`) and
// SPEC/ui/move-fleet-dialog.md (`MoveFleetDialog`): both render a
// `CtDialogShell` body of [title, CtSectionLabel-headed destination
// groups, trailing Cancel/Confirm Wrap] over the same 1 px/2 px
// `--border`/`--accent` radio-row outline contract (#2867 R1/R7).

import 'package:flutter/material.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_spacing.dart';
import '../chrome/ct_nine_patch_button.dart';

part 'move_units_dialog_base_styles.dart';
part 'move_units_dialog_base_scaffold.dart';
part 'move_units_dialog_base_row.dart';
