import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  const resolver = DebugConsoleGpTargetResolver();
  final players = [
    const DebugConsolePlayerSnapshot(
      id: 'gp1',
      displayName: 'France',
      isHuman: true,
      capitalProvinceId: 'oldWorld|P1',
    ),
    const DebugConsolePlayerSnapshot(
      id: 'gp2',
      displayName: 'England',
      isHuman: false,
      capitalProvinceId: 'oldWorld|P2',
    ),
    const DebugConsolePlayerSnapshot(
      id: 'gp3',
      displayName: 'Zed',
      isHuman: false,
      capitalProvinceId: null,
    ),
  ];

  test('resolves exact player id', () {
    final result = resolver.resolve(target: 'gp2', players: players);
    expect(result.playerId, 'gp2');
  });

  test('resolves case-insensitive display name', () {
    final result = resolver.resolve(target: 'france', players: players);
    expect(result.playerId, 'gp1');
  });

  test('rejects eliminated gp', () {
    final result = resolver.resolve(target: 'gp3', players: players);
    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('eliminated'));
  });

  test('rejects unknown target', () {
    final result = resolver.resolve(target: 'nope', players: players);
    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('Unknown'));
  });
}
