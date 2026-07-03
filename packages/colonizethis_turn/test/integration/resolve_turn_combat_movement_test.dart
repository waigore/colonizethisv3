import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/turn_resolver_test_harness.dart';

part 'resolve_turn_combat_part1_segment3_part.dart';
part 'resolve_turn_combat_part2_part1_combat_part.dart';
part 'resolve_turn_combat_part2_dialogue_order_engine_part.dart';
part 'resolve_turn_combat_part2_part2_segment1_part.dart';
part 'resolve_turn_combat_part2_part2_segment2_part.dart';

void main() {
  _resolve_turn_combat_part1_segment3_partTests();
  _resolve_turn_combat_part2_part1_combat_partTests();
  _resolve_turn_combat_part2_dialogue_order_engine_partTests();
  _resolve_turn_combat_part2_part2_segment1_partTests();
  _resolve_turn_combat_part2_part2_segment2_partTests();
}
