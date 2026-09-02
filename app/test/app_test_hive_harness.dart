// Shared Hive box opener for app widget tests (Refs #4680 Slice A).
//
// [suiteId] must be unique per test suite (or per caller when a shared helper
// module is imported by multiple suites) so parallel `flutter test` shards do
// not contend on `games.lock` (Refs #4175).

import 'dart:io';

import 'package:colonizethis_app/config/constants.dart';
import 'package:hive/hive.dart';

/// Opens an isolated Hive box for widget tests.
///
/// Default directory is `./.dart_tool/test_hive_$suiteId` on desktop hosts when
/// [directory] is null. On Android/iOS integration-test devices the app cwd is
/// read-only, so a unique [Directory.systemTemp] subdir is used instead
/// (Refs #4687 profile evidence on emulator).
Future<Box<dynamic>> openAppTestHiveBox({
  required String suiteId,
  String boxName = HiveBoxNames.games,
  Directory? directory,
}) async {
  final String hivePath;
  if (directory != null) {
    hivePath = directory.path;
  } else if (Platform.isAndroid || Platform.isIOS) {
    final tempDir = await Directory.systemTemp.createTemp('ct_test_hive_$suiteId');
    hivePath = tempDir.path;
  } else {
    hivePath = './.dart_tool/test_hive_$suiteId';
  }
  Hive.init(hivePath);
  return Hive.openBox<dynamic>(boxName);
}
