import 'package:colonizethis_world/src/world/fog_resolution.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/world/province_owner_cache.dart';
import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_turn/src/turn/end_of_turn_resolver.dart';
import 'package:colonizethis_world/src/world/fog_spy_reveal_decay.dart';

part 'fog_resolution_distant_sea_integration_part.dart';
part 'fog_resolution_distant_sea_part.dart';
part 'fog_resolution_initial_visibility_part.dart';
part 'fog_resolution_spy_clear_part.dart';
part 'fog_resolution_spy_decay_part.dart';

void main() {
  _fog_resolution_distant_sea_integration_testTests();
  _fog_resolution_distant_sea_testTests();
  _fog_resolution_initial_visibility_testTests();
  _fog_resolution_spy_clear_testTests();
  _fog_resolution_spy_decay_testTests();
}
