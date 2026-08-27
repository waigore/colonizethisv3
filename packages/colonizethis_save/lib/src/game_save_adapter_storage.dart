/// Shared Hive storage-id write / envelope-read SoT for [GameSaveAdapter].
/// Refs #4664.
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/package_logger.dart';
import 'package:hive/hive.dart';

import 'game_save_envelope_codec.dart';
import 'game_save_session.dart';

/// Writes a versioned envelope under [storageId] (named save or auto-save stem).
void putGameSaveEnvelopeAtStorageId(
  Box<dynamic> box,
  String storageId,
  Game game, {
  Orders draftOrders = const Orders(),
  Map<String, int> productionDesiredOutputByRecipe = const <String, int>{},
  String? displayName,
  DateTime? lastSavedAt,
}) {
  box.put(
    storageId,
    buildGameSaveEnvelope(
      game,
      draftOrders: draftOrders,
      productionDesiredOutputByRecipe: productionDesiredOutputByRecipe,
      displayName: displayName,
      lastSavedAt: lastSavedAt,
    ),
  );
}

/// Reads and parses the envelope at [gameId].
///
/// Returns null when the key is absent. When [strict] is false, incompatible
/// or malformed payloads log and return null. When [strict] is true, parse
/// errors (including [IncompatibleSaveFormatException]) propagate.
GameSaveSession? readGameSaveSessionAtStorageId(
  Box<dynamic> box,
  String gameId, {
  required bool strict,
  required CtLogger log,
}) {
  final raw = box.get(gameId);
  if (raw == null) {
    log.w('gameId=$gameId not found');
    return null;
  }
  if (strict) {
    final envelope = Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
    return parseGameSaveSessionEnvelope(envelope, gameId: gameId);
  }
  try {
    final envelope = Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
    return parseGameSaveSessionEnvelope(envelope, gameId: gameId);
  } catch (e, st) {
    log.e('load failed gameId=$gameId', error: e, stackTrace: st);
    return null;
  }
}
