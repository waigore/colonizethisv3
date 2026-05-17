import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:path/path.dart' as p;

void main() {
  group('tech catalog', () {
    test('contains basic gathering and transport techs', () {
      expect(techById(kTechIdCropRotation), isNotNull);
      expect(techById(kTechIdSawMill), isNotNull);
      expect(techById(kTechIdLandEnclosure), isNotNull);
      expect(techById(kTechIdRoadConstruction), isNotNull);
      expect(techById(kTechIdEarlySteamEngine), isNotNull);
    });

    test('prerequisites are consistent', () {
      final windSaw = techById(kTechIdWindSawMill)!;
      expect(windSaw.prerequisiteIds, contains(kTechIdSawMill));
      final seedDrill = techById(kTechIdSeedDrill)!;
      expect(seedDrill.prerequisiteIds, contains(kTechIdLandEnclosure));
      final rail = techById(kTechIdEarlySteamEngine)!;
      expect(rail.prerequisiteIds, contains(kTechIdRoadConstruction));
    });
  });

  group('effect summary (shared YAML)', () {
    test('university query prints authored effect lines', () async {
      final root = _repoRoot();
      final showTechDart = p.join(
        root,
        'tool',
        'show_tech',
        'bin',
        'show_tech.dart',
      );
      final result = await Process.run('dart', [
        showTechDart,
        '--query',
        kTechIdUniversity,
      ]);
      expect(result.exitCode, 0);
      final out = result.stdout as String;
      expect(out, contains('Fourth active research slot'));
      expect(out, contains('Master Artisans'));
    });
  });
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    final pub = File(p.join(dir.path, 'pubspec.yaml'));
    if (pub.existsSync() &&
        pub.readAsStringSync().contains('name: colonizethis')) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('repo root not found');
    }
    dir = parent;
  }
}
