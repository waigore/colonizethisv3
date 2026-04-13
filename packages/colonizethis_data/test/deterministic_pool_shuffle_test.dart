import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('shuffledPoolIndices returns empty for non-positive poolLength', () {
    expect(shuffledPoolIndices(poolLength: 0, seed: 42), isEmpty);
    expect(shuffledPoolIndices(poolLength: -1, seed: 42), isEmpty);
  });

  test('shuffledPoolIndices is stable for the same seed and length', () {
    const seed = 404;
    const n = 12;
    final a = shuffledPoolIndices(poolLength: n, seed: seed);
    final b = shuffledPoolIndices(poolLength: n, seed: seed);
    expect(a, b);
    expect(a.toSet().length, n);
    expect(a.toSet(), equals({for (var i = 0; i < n; i++) i}));
  });

  test('shuffledPoolIndices differs across seeds for fixed length', () {
    const n = 8;
    final x = shuffledPoolIndices(poolLength: n, seed: 1);
    final y = shuffledPoolIndices(poolLength: n, seed: 2);
    expect(x, isNot(y));
  });
}
