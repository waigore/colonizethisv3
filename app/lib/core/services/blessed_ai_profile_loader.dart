import 'dart:convert';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/services.dart';

import 'package:colonizethis_app/package_logger.dart';

final _log = packageLogger('data');

/// Loads blessed [AiProfile]s from `assets/profiles/` (excluding manifest).
class BlessedAiProfileLoader {
  const BlessedAiProfileLoader._();

  static const String _manifestAsset = 'assets/profiles/manifest.json';

  /// Profile names listed in [manifest] (sorted).
  static Future<List<String>> loadBlessedProfileNames() async {
    final manifestRaw = await rootBundle.loadString(_manifestAsset);
    final manifestDecoded = jsonDecode(manifestRaw);
    if (manifestDecoded is! Map<String, dynamic>) {
      return const [];
    }
    final profiles = manifestDecoded['profiles'];
    if (profiles is! List<dynamic>) {
      return const [];
    }
    final names = <String>[];
    for (final row in profiles) {
      if (row is Map<String, dynamic>) {
        final name = row['name'];
        if (name is String && name.isNotEmpty) {
          names.add(name);
        }
      }
    }
    names.sort();
    return names;
  }

  /// All blessed profiles keyed by manifest name.
  static Future<Map<String, AiProfile>> loadCatalog() async {
    final names = await loadBlessedProfileNames();
    if (names.isEmpty) {
      return const {};
    }
    final documents = <String, String>{};
    for (final name in names) {
      final assetPath = 'assets/profiles/$name.json';
      try {
        documents[name] = await rootBundle.loadString(assetPath);
      } on Object catch (e) {
        _log.w('app:ai_profile failed to load asset $assetPath: $e');
      }
    }
    if (documents.isEmpty) {
      return const {};
    }
    try {
      return loadAiProfilesFromJsonDocuments(documents);
    } on AiProfileBatchLoadException catch (e) {
      _log.e('app:ai_profile invalid blessed profile bundle: $e');
      return const {};
    }
  }
}
