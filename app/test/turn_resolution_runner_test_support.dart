import 'dart:convert';

/// Full turn pipeline phase count (historical SendPort regression embedded one
/// full game JSON per phase as before+after). Kept in sync with
/// `colonizethis_logic/src/turn/turn_resolution_sequence.dart`.
const int kTurnResolutionPhaseCountForBlobRegression = 14;

/// If we ever ship full per-phase snapshots on the isolate again, the UTF-8 JSON
/// blows up long before this (Refs #2277).
const int kMaxIsolateSuccessEnvelopeUtf8Bytes = 786432;

Object? deepToJsonEncodable(Object? value) {
  if (value == null || value is bool || value is num || value is String) {
    return value;
  }
  if (value is Map<Object?, Object?>) {
    final out = <String, Object?>{};
    for (final MapEntry<Object?, Object?> entry in value.entries) {
      out[entry.key.toString()] = deepToJsonEncodable(entry.value);
    }
    return out;
  }
  if (value is List<Object?>) {
    return value.map(deepToJsonEncodable).toList(growable: false);
  }
  return value.toString();
}

int mapUtf8JsonLength(Map<Object?, Object?> raw) {
  return utf8.encode(jsonEncode(deepToJsonEncodable(raw))).length;
}

