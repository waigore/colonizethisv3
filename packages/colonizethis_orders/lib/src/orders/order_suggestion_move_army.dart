import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'draft_orders_mutations.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_context.dart';
import 'order_suggestion_pass_context.dart';
import 'order_visibility.dart';

part 'order_suggestion_move_unit.dart';
part 'order_suggestion_army_move.dart';

/// Order-suggestion probes for civilian unit moves ([MoveOrder]) and army moves
/// ([ArmyMoveOrder]).
///
/// Behaviour is split by concern across part files of this library; all
/// top-level entry points remain importable from `order_suggestion_move_army.dart`:
///
/// - `order_suggestion_move_unit.dart` — civilian unit move suggestions
///   ([sortedMoveDestinationCandidateTileKeys], [suggestMoveOrders]).
/// - `order_suggestion_army_move.dart` — army move suggestions and the Move
///   Army picker ([armyMoveCandidateDestinationProvinceIds],
///   [ArmyMovePickerDestination], [armyMovePickerDestinations],
///   [suggestArmyMoveOrders]).
///
/// SPEC source of truth: SPEC/program/order-suggestions.md;
/// SPEC/program/movement.md; SPEC/ui/military-units-panel.md.
