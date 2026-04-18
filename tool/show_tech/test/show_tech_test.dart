import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:path/path.dart' as p;

void main() {
  group('tech catalog', () {
    test('contains basic gathering and transport techs', () {
      expect(techById('crop_rotation'), isNotNull);
      expect(techById('saw_mill'), isNotNull);
      expect(techById('land_enclosure'), isNotNull);
      expect(techById('road_construction'), isNotNull);
      expect(techById('early_steam_engine'), isNotNull);
    });

    test('prerequisites are consistent', () {
      final windSaw = techById('wind_saw_mill')!;
      expect(windSaw.prerequisiteIds, contains('saw_mill'));
      final seedDrill = techById('seed_drill')!;
      expect(seedDrill.prerequisiteIds, contains('land_enclosure'));
      final rail = techById('early_steam_engine')!;
      expect(rail.prerequisiteIds, contains('road_construction'));
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
        'university',
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
