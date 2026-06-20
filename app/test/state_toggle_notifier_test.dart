// Unit tests for the shared StateToggleNotifier (Refs #3279).

import 'package:colonizethis_app/core/utils/state_toggle_notifier.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _defaultTrueProvider = NotifierProvider<StateToggleNotifier, bool>(
  () => StateToggleNotifier(true),
);

final _defaultFalseProvider = NotifierProvider<StateToggleNotifier, bool>(
  () => StateToggleNotifier(false),
);

void main() {
  suppressLogsForTests();

  group('StateToggleNotifier', () {
    test('build returns the configured default (true)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(_defaultTrueProvider), isTrue);
    });

    test('build returns the configured default (false)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(_defaultFalseProvider), isFalse);
    });

    test('set assigns the exact value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(_defaultTrueProvider.notifier).set(false);
      expect(container.read(_defaultTrueProvider), isFalse);

      container.read(_defaultTrueProvider.notifier).set(true);
      expect(container.read(_defaultTrueProvider), isTrue);
    });

    test('toggle flips the current value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(_defaultFalseProvider.notifier).toggle();
      expect(container.read(_defaultFalseProvider), isTrue);

      container.read(_defaultFalseProvider.notifier).toggle();
      expect(container.read(_defaultFalseProvider), isFalse);
    });

    test('reset restores the configured default after mutation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(_defaultTrueProvider.notifier).set(false);
      expect(container.read(_defaultTrueProvider), isFalse);

      container.read(_defaultTrueProvider.notifier).reset();
      expect(container.read(_defaultTrueProvider), isTrue);
    });
  });
}
