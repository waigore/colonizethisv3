import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_force_feeding_shared_helper.dart';

const _helperRelative =
    'packages/colonizethis_economy/lib/src/economy/'
    'economy_military_navy_food_allocation.dart';
const _forceFeedingRelative =
    'packages/colonizethis_economy/lib/src/economy/force_feeding_readiness.dart';
const _allocRelative =
    'packages/colonizethis_economy/lib/src/economy/'
    'economy_consumption_allocation.dart';

const _helperSource = r'''
MilitaryNavyFoodAllocation allocateMilitaryNavyFood({
  required Stockpile stockpile,
}) {
  return const MilitaryNavyFoodAllocation();
}
''';

const _okConsumer = r'''
void previewForceFeeding() {
  allocateMilitaryNavyFood(stockpile: const Stockpile());
}
''';

const _bypassForceFeeding = r'''
void previewForceFeeding() {
  consumeMilitaryFood(stockpile: const Stockpile());
  consumeNavyFood(stockpile: const Stockpile());
}
''';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckEconomyForceFeedingSharedHelper', () {
    test('passes when preview and allocate call allocateMilitaryNavyFood', () {
      final root = Directory.systemTemp.createTempSync('ff_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, _helperSource);
      _writeFile(root, _forceFeedingRelative, _okConsumer);
      _writeFile(root, _allocRelative, _okConsumer);

      final logs = <String>[];
      final code = runCheckEconomyForceFeedingSharedHelper(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when force_feeding_readiness calls consumeMilitaryFood', () {
      final root = Directory.systemTemp.createTempSync('ff_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, _helperSource);
      _writeFile(root, _forceFeedingRelative, _bypassForceFeeding);
      _writeFile(root, _allocRelative, _okConsumer);

      final logs = <String>[];
      final code = runCheckEconomyForceFeedingSharedHelper(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('force_feeding_readiness.dart'));
    });
  });
}
