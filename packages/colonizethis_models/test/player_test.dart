import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('Player', () {
    test('toJson/fromJson round-trip', () {
      const p = Player(id: 'p1', displayName: 'Spain', isHuman: true);
      final json = p.toJson();
      final p2 = Player.fromJson(json);
      expect(p2.id, 'p1');
      expect(p2.displayName, 'Spain');
      expect(p2.isHuman, true);
      expect(p2.stockpile, Stockpile.empty);
      expect(p2.workerPool, WorkerPool.empty);
      expect(p2.treasury, 0);
    });
    test('equality', () {
      const a = Player(id: 'p1', displayName: 'Spain', isHuman: true);
      const b = Player(id: 'p1', displayName: 'Spain', isHuman: true);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
    test('equality false when different', () {
      const a = Player(id: 'p1', displayName: 'Spain', isHuman: true);
      const b = Player(id: 'p2', displayName: 'Spain', isHuman: true);
      expect(a == b, false);
      const c = Player(id: 'p1', displayName: 'France', isHuman: true);
      expect(a == c, false);
      expect(a == Object(), false);
    });
  });
}
