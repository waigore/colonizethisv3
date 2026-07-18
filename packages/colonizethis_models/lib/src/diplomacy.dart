/// Diplomacy models barrel. SPEC/game/diplomacy.md, diplomacy-resolution.md.
///
/// Concern libraries live under `diplomacy/`; this file re-exports them so
/// `package:colonizethis_models/colonizethis_models.dart` and relative
/// `diplomacy.dart` imports stay stable (Refs #4068).

export 'diplomacy/debug_tokens.dart';
export 'diplomacy/events.dart';
export 'diplomacy/orders.dart';
export 'diplomacy/overtures.dart';
export 'diplomacy/relations.dart';
export 'diplomacy/treaty_states.dart';
