import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'package_logger.dart';

final _log = packageLogger('session');

/// Process exit code when `--profiles` loading fails (Refs #3437).
const int kExitProfileLoadFailed = 9;

/// Thrown when `--profiles` cannot be loaded: a missing directory or an
/// unparseable / schema-invalid matched profile file. The run must abort with
/// [kExitProfileLoadFailed] before resolving turns.
/// SPEC/program/run_observer_game-tool.md § Per-GP AI profiles.
class ObserverProfileLoadException implements Exception {
  ObserverProfileLoadException(this.message);

  /// User-facing failure description (written to stderr by the caller).
  final String message;

  @override
  String toString() => message;
}

/// Loads per-Great-Power [AiProfile]s from [dir], keyed by `playerId`.
///
/// Reads `<dir>/<playerId>.json` for each id in [playerIds]. A Great Power
/// without a matching file is omitted from the result (it keeps its default
/// hardcoded personality). Files in [dir] that match no id in [playerIds] are
/// ignored and logged once at `warning`. Throws [ObserverProfileLoadException]
/// when [dir] does not exist or any matched file is unparseable or invalid.
Map<String, AiProfile> loadObserverProfiles({
  required String dir,
  required Iterable<String> playerIds,
}) {
  final directory = Directory(dir);
  if (!directory.existsSync()) {
    throw ObserverProfileLoadException('profiles directory not found: $dir');
  }

  final idSet = playerIds.toSet();
  final loaded = <String, AiProfile>{};
  for (final id in idSet) {
    final file = File('${directory.path}/$id.json');
    if (!file.existsSync()) continue;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('profile JSON must be a JSON object');
      }
      loaded[id] = AiProfile.fromJson(decoded);
    } on Object catch (e) {
      throw ObserverProfileLoadException(
        'failed to load profile for "$id" (${file.path}): $e',
      );
    }
  }

  for (final entity in directory.listSync().whereType<File>()) {
    final name = entity.uri.pathSegments.last;
    if (!name.endsWith('.json')) continue;
    final id = name.substring(0, name.length - '.json'.length);
    if (!idSet.contains(id)) {
      _log.w('observer:profile_unmatched file=${entity.path}');
    }
  }

  _log.i('observer:profiles_loaded count=${loaded.length}');
  return loaded;
}
