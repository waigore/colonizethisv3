import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_region_label.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        OrderEngine,
        allProvinces,
        buildPlayerView,
        homeFleetIdFor,
        kWorkTargetExplore,
        provinceIdsAdjacentToSeaZone,
        regionIdForSeaZone,
        suggestWorkOrders;
import 'package:colonizethis_models/colonizethis_models.dart'
    show MoveOrder, ProvinceId, Unit, WorkOrder, kUnitTypeExplorer;
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/l10n/app_localizations.dart';
import 'package:colonizethis_app/main.dart' show bootstrapForIntegrationTest;
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

part 'new_game_fleet_reaches_new_world_e2e_test_body_part.g.dart';
