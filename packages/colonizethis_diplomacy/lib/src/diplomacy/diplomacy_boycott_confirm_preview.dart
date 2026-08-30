/// First-order Boycott / Revoke Boycott confirm copy (Refs #4584).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Name at most this many colony display names; otherwise say "your colony tribes".
const kBoycottNamedColonyDisplayCap = 3;

/// Cost / Effect lines for applying a colony-trade embargo.
List<String> boycottConfirmPreviewLines({
  required Game game,
  required String humanPlayerId,
  required String targetDisplayName,
}) {
  final colonies = boycottColoniesPhrase(
    game: game,
    humanPlayerId: humanPlayerId,
  );
  return [
    'Cost: No treasury charge.',
    'Effect: World-market deals between $targetDisplayName and $colonies '
        'will not fill in either direction.',
    'Effect: $targetDisplayName cannot purchase land, grant aid, or set '
        'subsidies toward $colonies.',
    'Effect: Any subsidies $targetDisplayName already pays $colonies are '
        'cancelled when this resolves.',
  ];
}

/// Cost / Effect lines for ending a colony-trade embargo.
List<String> revokeBoycottConfirmPreviewLines({
  required Game game,
  required String humanPlayerId,
  required String targetDisplayName,
}) {
  final colonies = boycottColoniesPhrase(
    game: game,
    humanPlayerId: humanPlayerId,
  );
  return [
    'Cost: No treasury charge.',
    'Effect: Ends the embargo so $targetDisplayName may again trade with, '
        'purchase land in, and grant aid or subsidies toward $colonies.',
  ];
}

/// Display-name phrase for the human's current colony Tribes (no raw ids).
String boycottColoniesPhrase({
  required Game game,
  required String humanPlayerId,
}) {
  final names = <String>[];
  for (final colony in game.colonyStates) {
    if (colony.colonyOfGpId != humanPlayerId) {
      continue;
    }
    final name = _tribeDisplayName(game, colony.tribeId);
    if (name == null) {
      continue;
    }
    names.add(name);
  }
  names.sort();
  if (names.isEmpty || names.length > kBoycottNamedColonyDisplayCap) {
    return 'your colony tribes';
  }
  if (names.length == 1) {
    return names.single;
  }
  if (names.length == 2) {
    return '${names[0]} and ${names[1]}';
  }
  return '${names[0]}, ${names[1]}, and ${names[2]}';
}

String? _tribeDisplayName(Game game, String tribeId) {
  for (final tribe in game.tribes) {
    if (tribe.id != tribeId) {
      continue;
    }
    final name = (tribe.displayName ?? '').trim();
    if (name.isEmpty) {
      return null;
    }
    return name;
  }
  return null;
}
