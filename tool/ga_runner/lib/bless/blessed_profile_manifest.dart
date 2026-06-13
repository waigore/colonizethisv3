import 'dart:convert';
import 'dart:io';

/// One blessed profile entry in `app/assets/profiles/manifest.json`.
class BlessedProfileManifestEntry {
  const BlessedProfileManifestEntry({
    required this.name,
    required this.sourceRunId,
    required this.sourceProfileId,
    required this.sourceFitness,
    required this.blessedAt,
  });

  final String name;
  final String sourceRunId;
  final String sourceProfileId;
  final double sourceFitness;
  final String blessedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'source_run_id': sourceRunId,
    'source_profile_id': sourceProfileId,
    'source_fitness': sourceFitness,
    'blessed_at': blessedAt,
  };

  factory BlessedProfileManifestEntry.fromJson(Map<String, dynamic> json) {
    return BlessedProfileManifestEntry(
      name: json['name'] as String? ?? '',
      sourceRunId: json['source_run_id'] as String? ?? '',
      sourceProfileId: json['source_profile_id'] as String? ?? '',
      sourceFitness: (json['source_fitness'] as num?)?.toDouble() ?? 0.0,
      blessedAt: json['blessed_at'] as String? ?? '',
    );
  }
}

/// Blessed profile manifest at `app/assets/profiles/manifest.json`.
class BlessedProfileManifest {
  BlessedProfileManifest({List<BlessedProfileManifestEntry>? profiles})
    : profiles = profiles ?? <BlessedProfileManifestEntry>[];

  final List<BlessedProfileManifestEntry> profiles;

  BlessedProfileManifestEntry? entryByName(String name) {
    for (final entry in profiles) {
      if (entry.name == name) {
        return entry;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'profiles': profiles.map((e) => e.toJson()).toList(),
  };

  factory BlessedProfileManifest.fromJson(Map<String, dynamic> json) {
    final raw = json['profiles'];
    if (raw is! List<dynamic>) {
      return BlessedProfileManifest();
    }
    return BlessedProfileManifest(
      profiles: [
        for (final row in raw)
          if (row is Map<String, dynamic>)
            BlessedProfileManifestEntry.fromJson(row),
      ],
    );
  }

  static BlessedProfileManifest readFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return BlessedProfileManifest();
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('manifest must be a JSON object: $path');
    }
    return BlessedProfileManifest.fromJson(decoded);
  }

  Future<void> writeFile(String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(toJson())}\n',
    );
  }
}

String blessedProfilesDir(String repoRoot) => '$repoRoot/app/assets/profiles';

String blessedManifestPath(String repoRoot) =>
    '${blessedProfilesDir(repoRoot)}/manifest.json';

String blessedProfileAssetPath(String repoRoot, String name) =>
    '${blessedProfilesDir(repoRoot)}/$name.json';

/// Locates a GA run directory by [runId] under [searchRoot] (non-recursive).
String? resolveRunDirectoryById(String searchRoot, String runId) {
  final direct = Directory('$searchRoot/$runId');
  if (direct.existsSync()) {
    return direct.path;
  }
  final parent = Directory(searchRoot);
  if (!parent.existsSync()) {
    return null;
  }
  for (final entity in parent.listSync()) {
    if (entity is Directory && entity.uri.pathSegments.last == runId) {
      return entity.path;
    }
  }
  return null;
}
