// SPEC/program/game-setup-pipeline.md. Builds Game from generated maps and config.
// Map generation is done by the caller (app/colonizethis_map); this module does
// province assignment, build state, and capital auto-choice.

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'capital_choice.dart';
import 'gp_land_connectivity_repair.dart';
import 'gp_starting_grain.dart';
import 'town_capital_occupancy.dart';
import 'init_town_roads.dart';
import 'setup_exceptions.dart';
import '../constants.dart';
import '../diplomacy/diplomacy_relation_lookup.dart';
import 'initial_visibility.dart';
import '../world/army_migration.dart';
import '../world/naval.dart';
import '../world/ship_instance_allocate.dart';
import 'province_assignment.dart';
import 'province_name_fallback.dart';

part 'game_setup_create.dart';
part 'game_setup_helpers.dart';
part 'game_setup_ownership.dart';

final _log = packageLogger();
