/// Batch loading and validation of [AiProfile] JSON documents.
///
/// Shared by observer `--profiles`, app asset bundles, and GA blessing.
/// SPEC/program/ga-runner.md § Blessed profiles; Refs #3444.
library;

import 'dart:convert';

import 'ai_profile.dart';

/// Thrown when one or more profile documents fail validation.
class AiProfileBatchLoadException implements Exception {
  AiProfileBatchLoadException(this.errors);

  /// Map of source key (filename or logical id) → error message.
  final Map<String, String> errors;

  @override
  String toString() =>
      'AiProfileBatchLoadException: ${errors.length} profile(s) failed';
}

/// Parses [jsonDocuments] (key → raw JSON string) into validated [AiProfile]s.
///
/// Keys are logical names (e.g. `aggressive_v2` or `england`); values are
/// full profile JSON objects. Throws [AiProfileBatchLoadException] when any
/// document is unparseable or schema-invalid.
Map<String, AiProfile> loadAiProfilesFromJsonDocuments(
  Map<String, String> jsonDocuments,
) {
  final loaded = <String, AiProfile>{};
  final errors = <String, String>{};
  for (final entry in jsonDocuments.entries) {
    try {
      final decoded = jsonDecode(entry.value);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('profile "${entry.key}" JSON must be an object');
      }
      loaded[entry.key] = AiProfile.fromJson(decoded);
    } on Object catch (e) {
      errors[entry.key] = e.toString();
    }
  }
  if (errors.isNotEmpty) {
    throw AiProfileBatchLoadException(errors);
  }
  return Map<String, AiProfile>.unmodifiable(loaded);
}
