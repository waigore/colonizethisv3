import 'package:hive/hive.dart';

import 'game_save_envelope_codec.dart';
import 'game_save_keys.dart';
import 'loadable_save_entry.dart';

/// Minimum `saveFormatVersion` included by listLoadableSaves.
const int kListGateSaveFormatVersion = 3;

/// Fixed label for the auto-save row in listLoadableSaves (UI may localize).
const String kAutoSaveListLabel = 'Auto-save';

/// Lists all game ids stored in [box]. Excludes internal map-data keys and
/// [autoSaveSlotId].
///
/// A key is treated as a game id unless it ends with a map-data suffix AND
/// its prefix exists as a separate key in the box (proving it is map data for
/// that game). This ensures game ids like `mygame_tileMapByRegion` are not
/// incorrectly excluded when no corresponding `mygame` key exists.
List<String> listStoredGameIds(
  Box<dynamic> box, {
  required String autoSaveSlotId,
}) {
  final allKeys = box.keys.whereType<String>().toSet();

  final definiteGameIds = allKeys
      .where(
        (k) =>
            k != autoSaveSlotId &&
            !k.endsWith(kSuffixTileMapByRegion) &&
            !k.endsWith(kSuffixTopologyByRegion) &&
            !k.endsWith(kSuffixCombinedTopology) &&
            !k.endsWith(kSuffixWarpLinks),
      )
      .toSet();

  final result = <String>[...definiteGameIds];

  for (final key in allKeys) {
    for (final suffix in kMapDataKeySuffixes) {
      if (!key.endsWith(suffix)) {
        continue;
      }
      final prefix = key.substring(0, key.length - suffix.length);
      if (prefix != autoSaveSlotId && !definiteGameIds.contains(prefix)) {
        result.add(key);
      }
      break;
    }
  }

  return result;
}

/// Parses a list-gate row from a raw envelope, or null when ineligible.
LoadableSaveEntry? tryParseLoadableSaveEntry({
  required String storageId,
  required Object? raw,
  required LoadableSaveKind kind,
  String? forcedLabel,
}) {
  if (raw is! Map<dynamic, dynamic>) {
    return null;
  }
  final envelope = Map<String, dynamic>.from(raw);
  final version = envelope[kSaveFormatVersionKey];
  if (version is! int || version < kListGateSaveFormatVersion) {
    return null;
  }
  final metaRaw = envelope[kListMetaKey];
  if (metaRaw is! Map<dynamic, dynamic>) {
    return null;
  }
  final meta = Map<String, dynamic>.from(metaRaw);
  final lastSavedRaw = meta[kListMetaLastSavedAtKey];
  if (lastSavedRaw is! String || lastSavedRaw.isEmpty) {
    return null;
  }
  final lastSavedAt = DateTime.tryParse(lastSavedRaw)?.toUtc();
  if (lastSavedAt == null) {
    return null;
  }
  final turnRaw = meta[kListMetaTurnNumberKey];
  final turnNumber = turnRaw is int ? turnRaw : null;
  final yearRaw = meta[kListMetaCalendarYearKey];
  final calendarYear = yearRaw is int ? yearRaw : null;
  final nationRaw = meta[kListMetaHumanNationKey];
  final humanNation = nationRaw is String && nationRaw.isNotEmpty
      ? nationRaw
      : null;
  final displayName = parseDisplayName(envelope[kDisplayNameKey]);
  final label =
      forcedLabel ??
      ((displayName != null && displayName.isNotEmpty)
          ? displayName
          : storageId);
  return LoadableSaveEntry(
    storageId: storageId,
    label: label,
    kind: kind,
    turnNumber: turnNumber,
    calendarYear: calendarYear,
    humanNation: humanNation,
    lastSavedAt: lastSavedAt,
  );
}

/// Manuals newest-first, then optional pinned auto-save when [autoEntry] set.
List<LoadableSaveEntry> assembleLoadableSaveList({
  required List<LoadableSaveEntry> manuals,
  LoadableSaveEntry? autoEntry,
}) {
  final sorted = List<LoadableSaveEntry>.from(manuals);
  sorted.sort((a, b) {
    final aAt = a.lastSavedAt;
    final bAt = b.lastSavedAt;
    if (aAt == null && bAt == null) {
      return a.storageId.compareTo(b.storageId);
    }
    if (aAt == null) {
      return 1;
    }
    if (bAt == null) {
      return -1;
    }
    final byTime = bAt.compareTo(aAt);
    if (byTime != 0) {
      return byTime;
    }
    return a.storageId.compareTo(b.storageId);
  });

  final result = <LoadableSaveEntry>[];
  if (autoEntry != null) {
    result.add(autoEntry);
  }
  result.addAll(sorted);
  return result;
}
