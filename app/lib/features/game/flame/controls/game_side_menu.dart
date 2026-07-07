import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../config/routes.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../widgets/dialogs/game_parameters_dialog.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_panel.dart';
import '../../../../widgets/ct_spacing.dart';

part 'game_side_menu_panel.dart';
part 'game_side_menu_scrim.dart';
