import 'package:colonizethis_logic/colonizethis_logic.dart' show kRegionNewWorld;
import 'package:colonizethis_models/colonizethis_models.dart';

part 'debug_command_helpers_messages.dart';
part 'debug_command_helpers_guards.dart';
part 'debug_command_helpers_game.dart';

typedef DebugCommandResult = ({Game? game, String message});

/// Canonical per-command labels used to compose debug-console handler messages.
///
/// Centralizes the `Debug <label>` prefixes so guard/short-circuit text stays
/// consistent across handlers (generalizes the prior `set_diplomacy` `_kPrefix`
/// approach to every handler). Refs #3655.
abstract final class DebugCommandLabel {
  static const spawn = 'spawn';
  static const treasuryCredit = 'treasury credit';
  static const addMoney = 'add_money';
  static const addWorker = 'add_worker';
  static const addResource = 'add_resource';
  static const revealProvince = 'reveal_province';
  static const flipProvince = 'flip_province';
  static const setDiplomacy = 'set_diplomacy';
}
