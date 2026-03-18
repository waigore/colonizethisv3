import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_app/core/services/game_service.dart';

void main() {
  suppressLogsForTests();

  group('GameService cache and branches', () {
    late Box<dynamic> box;
    late GameService service;
    late Directory hiveDir;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp('ct_app_test_hive_');
      Hive.init(hiveDir.path);
      box = await Hive.openBox<dynamic>('games_cache');
      service = GameService(box, GameSaveAdapter());
    });

    tearDown(() async {
      await box.clear();
      await box.close();
      await Hive.close();
      await hiveDir.delete(recursive: true);
    });

    test('getMapData returns null for unknown game id', () {
      final result = service.getMapData('no-such-game');
      expect(result, isNull);
    });
  });
}

