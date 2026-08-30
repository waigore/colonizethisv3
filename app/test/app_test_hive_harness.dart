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
/// Default directory is `./.dart_tool/test_hive_$suiteId` when [directory] is
/// null. Pass [boxName] for non-games boxes (e.g. [HiveBoxNames.settings]).
Future<Box<dynamic>> openAppTestHiveBox({
  required String suiteId,
  String boxName = HiveBoxNames.games,
  Directory? directory,
}) async {
  final hivePath = directory?.path ?? './.dart_tool/test_hive_$suiteId';
  Hive.init(hivePath);
  return Hive.openBox<dynamic>(boxName);
}
