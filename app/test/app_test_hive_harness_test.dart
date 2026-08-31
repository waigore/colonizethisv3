import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';

void main() {
  test('openAppTestHiveBox opens an isolated games box on desktop (Refs #4687)', () async {
    final box = await openAppTestHiveBox(suiteId: 'harness_desktop');
    addTearDown(() async {
      await box.close();
    });
    expect(box.isOpen, isTrue);
    expect(box.name, isNotEmpty);
  });
}
