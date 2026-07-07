// Order helpers + Choose-tech dialog for `TechnologyPanel`.
// Split out of `technology_panel.dart` to keep that file under the
// 700-line `repo.game_widgets_file_size` cap (Refs #2864 S2/S3 + repo
// lint cap).
//
// Choose-tech dialog (Refs #2864 S4): dark editorial-monocle modal
// dismissible by the close button. Backed by `CtDialogShell` plus the
// canonical `EditorialMonoclePalette.dialogScrim` `barrierColor` per
// `SPEC/ui/technology-panel.md` § Choose-tech dialog and
// `SPEC/ui/pixel-art-ui-catalog.md` § Dialog scrim.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_confirm_dialog.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/strict_asset_icon.dart';
import 'tech_ui_helpers.dart';
import 'tech_gp_pennant_row.dart';

part 'technology_panel_choose_tech_dialog.dart';
part 'technology_panel_choose_tech_dialog_rows.dart';
part 'technology_panel_order_mutations.dart';
