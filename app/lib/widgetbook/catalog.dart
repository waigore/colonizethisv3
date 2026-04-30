// coverage:ignore-file
// Dev-only Widgetbook catalog; excluded from app coverage gate via instrumentation.
import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import '../config/themes.dart';
import '../features/game/widgets/civilian_units_panel.dart';
import '../features/game/widgets/diplomacy_panel.dart';
import '../features/game/widgets/military_units_panel.dart';
import '../features/game/widgets/naval_units_panel.dart';
import '../features/game/widgets/production_panel.dart';
import '../features/game/widgets/production_panel_demo_data.dart';
import '../features/game/widgets/province_sea_zone_detail_overlay.dart';
import '../features/game/widgets/province_overlay_demo_data.dart';
import '../features/game/widgets/tech_tree_widget.dart';
import '../features/game/screens/technology_screen.dart';
import '../features/game/dialogue/intervention_dialogue_overlay.dart';
import '../features/game/widgets/train_civilians_dialog.dart';
import '../features/game/widgets/train_military_dialog.dart';
import '../features/game/widgets/turn_news_dialog.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../widgets/debug_init_game.dart';
import '../widgets/ct_choice_chip.dart';
import '../widgets/debug_map_visibility_story.dart';
import '../widgets/game_setup.dart';
import '../widgets/main_menu.dart';
import '../widgets/ct_nine_patch_button.dart';
import '../widgets/ct_region_map.dart';
import '../widgets/ct_transfer_list.dart';

/// Invoked from `lib/widgetbook.dart` [main]; safe to call from tests after binding init.

part 'catalog_body_part.g.dart';
