/// Indexed faction display-name lookup for app UI.
///
/// Wraps [Game.factionDisplayNameById] so confirmation, diplomacy, and overlay
/// copy share one source of truth (Refs #4512).
library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

String displayNameForFaction(Game game, String id) =>
    game.factionDisplayNameById(id) ?? id;
