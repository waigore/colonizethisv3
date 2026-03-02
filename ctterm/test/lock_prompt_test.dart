// Tests for lock-prompt flow. SPEC/tui/ctterm.md §5.1.

import 'package:ctterm/save_service.dart';
import 'package:ctterm/screens/lock_prompt_screen.dart';
import 'package:ctterm/startup_check.dart';
import 'package:test/test.dart';

void main() {
  group('runStartupSaveCheck', () {
    test('returns true when ensureSaveServiceReady throws StaleLockException', () async {
      final result = await runStartupSaveCheck(
        '/some/dir',
        ensureReady: (_) async => throw StaleLockException('/some/dir'),
      );
      expect(result, isTrue);
    });

    test('returns false when ensureSaveServiceReady completes', () async {
      final result = await runStartupSaveCheck(
        null,
        ensureReady: (_) async {},
      );
      expect(result, isFalse);
    });

    test('returns false when ensureSaveServiceReady throws non-StaleLockException', () async {
      final result = await runStartupSaveCheck(
        null,
        ensureReady: (_) async => throw Exception('other'),
      );
      expect(result, isFalse);
    });
  });

  group('LockPromptScreen (SPEC/tui/ctterm.md §5.1)', () {
    test('can be constructed with onRemoveAndContinue and onQuit callbacks', () {
      var removeCalled = false;
      var quitCalled = false;
      final screen = LockPromptScreen(
        onRemoveAndContinue: () => removeCalled = true,
        onQuit: () => quitCalled = true,
      );
      expect(screen.onRemoveAndContinue, isNotNull);
      expect(screen.onQuit, isNotNull);

      screen.onRemoveAndContinue();
      expect(removeCalled, isTrue);

      screen.onQuit();
      expect(quitCalled, isTrue);
    });

    test('callbacks are invoked when screen would dispatch Y or N (contract)', () {
      var removeCount = 0;
      var quitCount = 0;
      final screen = LockPromptScreen(
        onRemoveAndContinue: () => removeCount++,
        onQuit: () => quitCount++,
      );
      screen.onRemoveAndContinue();
      expect(removeCount, 1);
      screen.onQuit();
      expect(quitCount, 1);
    });
  });
}
