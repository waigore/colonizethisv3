// Tests for ctterm save service data dir and listGameIds. SPEC/tui/ctterm.md.

import 'dart:io';

import 'package:ctterm/save_service.dart';
import 'package:test/test.dart';

void main() {
  group('getCttermDataDir', () {
    test('returns override when provided and non-empty', () {
      expect(getCttermDataDir('/custom/path'), equals('/custom/path'));
    });

    test('uses default when override is null', () {
      final dir = getCttermDataDir(null);
      expect(dir, isNotEmpty);
      expect(dir, contains('colonizethis_ctterm'));
    });
  });

  group('listGameIds', () {
    test('returns empty list when data dir has no saves', () async {
      final tempDir = Directory.systemTemp.createTempSync('ctterm_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final ids = await listGameIds(tempDir.path);
      expect(ids, isEmpty);
    });
  });
}
