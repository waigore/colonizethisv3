import 'package:colonizethis_logic/di.dart';
import 'package:colonizethis_test/test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('logic di exposes orderSuggestionApiProvider for AI composition', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(orderSuggestionApiProvider), isNotNull);
  });
}
