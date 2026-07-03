import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_world/src/world/connectivity_blockade_target.dart';
import '../world_test_support/world_test_support.dart';

part 'connectivity_resolver_blockade_cross_region_part.dart';
part 'connectivity_resolver_blockade_missions_part.dart';
part 'connectivity_resolver_blockade_part.dart';
part 'connectivity_resolver_non_gp_capital_part.dart';
part 'connectivity_resolver_non_gp_part.dart';

void main() {
  _connectivity_resolver_blockade_cross_region_testTests();
  _connectivity_resolver_blockade_missions_testTests();
  _connectivity_resolver_blockade_testTests();
  _connectivity_resolver_non_gp_capital_testTests();
  _connectivity_resolver_non_gp_testTests();
}
