import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_context.dart';
import 'order_suggestion_pass_context.dart';

// Naval and diplomatic order-suggestion families share this library's imports
// and the shared [effectiveOrderResolutionContext] helper from
// [order_suggestion_pass_context.dart]. The naval move/mission suggesters live
// in the `_naval` part fragment and the diplomatic / declare-war suggesters in
// the `_diplomatic` part fragment (Refs #3290 Phase 0 file decomposition).
part 'order_suggestion_naval.dart';
part 'order_suggestion_diplomatic.dart';
