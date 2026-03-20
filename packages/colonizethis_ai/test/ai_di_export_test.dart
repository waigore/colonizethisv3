import 'package:colonizethis_ai/di.dart';
import 'package:colonizethis_test/test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('di re-exports orderSuggestionApiProvider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(orderSuggestionApiProvider), isNotNull);
  });
}
