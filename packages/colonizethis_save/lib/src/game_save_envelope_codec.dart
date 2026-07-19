import 'package:colonizethis_data/colonizethis_data.dart'
    show reconcileGeneralsToGeneralCap;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'game_save_keys.dart';
import 'game_save_session.dart';
import 'incompatible_save_format_exception.dart';
import 'reconcile_legacy_spy_work.dart';

/// Current save format version for game envelopes.
/// v2 adds mid-turn draft fields; v3 adds list metadata (`listMeta`).
/// v1/v2 remain readable; only v3+ appears in listLoadableSaves.
const int kSaveFormatVersion = 3;

const Set<int> kSupportedSaveFormatVersions = {1, 2, kSaveFormatVersion};

/// Builds the versioned Hive envelope for [game].
Map<String, dynamic> buildGameSaveEnvelope(
  Game game, {
  Orders draftOrders = const Orders(),
  Map<String, int> productionDesiredOutputByRecipe = const <String, int>{},
  String? displayName,
  DateTime? lastSavedAt,
}) {
  return <String, dynamic>{
    kSaveFormatVersionKey: kSaveFormatVersion,
    kSaveGamePayloadKey: game.toJson(),
    kDraftOrdersKey: draftOrders.toJson(),
    kProductionDesiredOutputKey: productionDesiredOutputByRecipe,
    if (displayName != null) kDisplayNameKey: displayName,
    kListMetaKey: buildGameSaveListMeta(game, lastSavedAt: lastSavedAt),
  };
}

/// List-row metadata embedded in every envelope (v3+).
Map<String, dynamic> buildGameSaveListMeta(Game game, {DateTime? lastSavedAt}) {
  final turn = game.worldState.turnState.turnNumber;
  final mapping = game.turnTimeMapping;
  final year = mapping?.yearAtTurn(turn);
  String? nation;
  for (final player in game.players) {
    if (player.isHuman) {
      nation = player.displayName;
      break;
    }
  }
  final savedAt = (lastSavedAt ?? DateTime.now()).toUtc();
  return <String, dynamic>{
    kListMetaLastSavedAtKey: savedAt.toIso8601String(),
    kListMetaTurnNumberKey: turn,
    if (year != null) kListMetaCalendarYearKey: year,
    if (nation != null && nation.isNotEmpty) kListMetaHumanNationKey: nation,
  };
}

/// Shared session parse used by lenient and strict load paths.
/// Throws [IncompatibleSaveFormatException] for bad version/payload.
GameSaveSession parseGameSaveSessionEnvelope(
  Map<String, dynamic> envelope, {
  required String gameId,
}) {
  final versionRaw = envelope[kSaveFormatVersionKey];
  if (versionRaw is! int ||
      !kSupportedSaveFormatVersions.contains(versionRaw)) {
    throw IncompatibleSaveFormatException(
      'Incompatible save format for gameId=$gameId version=$versionRaw',
    );
  }
  final gameRaw = envelope[kSaveGamePayloadKey];
  if (gameRaw is! Map<dynamic, dynamic>) {
    throw IncompatibleSaveFormatException(
      'Invalid save payload for gameId=$gameId',
    );
  }
  final game = reconcileLegacySpyWorkOrders(
    reconcileGeneralsToGeneralCap(
      Game.fromJson(Map<String, dynamic>.from(gameRaw)),
    ),
  );
  return GameSaveSession(
    game: game,
    draftOrders: parseDraftOrders(envelope[kDraftOrdersKey]),
    productionDesiredOutputByRecipe: parseDesiredOutput(
      envelope[kProductionDesiredOutputKey],
    ),
    displayName: parseDisplayName(envelope[kDisplayNameKey]),
  );
}

Orders parseDraftOrders(Object? raw) {
  if (raw is! Map<dynamic, dynamic>) {
    return const Orders();
  }
  return Orders.fromJson(Map<String, dynamic>.from(raw));
}

Map<String, int> parseDesiredOutput(Object? raw) {
  if (raw is! Map<dynamic, dynamic>) {
    return const <String, int>{};
  }
  final out = <String, int>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String || value is! int || value < 0) {
      continue;
    }
    out[key] = value;
  }
  return out;
}

String? parseDisplayName(Object? raw) {
  if (raw is! String || raw.isEmpty) {
    return null;
  }
  return raw;
}
