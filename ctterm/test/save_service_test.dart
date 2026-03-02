// Tests for ctterm save service data dir, listGameIds, and lock handling.
// SPEC/tui/ctterm.md §5.1, SPEC/program/save-load.md.

import 'dart:io';

import 'package:ctterm/save_service.dart';
import 'package:path/path.dart' as path;
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

  group('lock handling (SPEC/tui/ctterm.md §5.1)', () {
    test('StaleLockException has dataDir set', () {
      const dir = '/some/data/dir';
      final e = StaleLockException(dir);
      expect(e.dataDir, equals(dir));
      expect(e.toString(), contains(dir));
    });

    test('removeStaleLock deletes lock file when present', () {
      final tempDir = Directory.systemTemp.createTempSync('ctterm_lock_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final lockPath = path.join(tempDir.path, gamesLockFilename);
      File(lockPath).writeAsStringSync('stale');
      expect(File(lockPath).existsSync(), isTrue);

      removeStaleLock(tempDir.path);

      expect(File(lockPath).existsSync(), isFalse);
    });

    test('removeStaleLock is no-op when lock file absent', () {
      final tempDir = Directory.systemTemp.createTempSync('ctterm_lock_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final lockPath = path.join(tempDir.path, gamesLockFilename);
      expect(File(lockPath).existsSync(), isFalse);

      removeStaleLock(tempDir.path);

      expect(File(lockPath).existsSync(), isFalse);
    });
  });
}
