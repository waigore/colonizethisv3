import 'package:run_observer_game/run_observer_game_cli.dart';
import 'package:test/test.dart';

void main() {
  test('help exits 0 and mentions melos', () {
    final out = <String>[];
    final err = <String>[];
    final code = runObserverGameCli(
      ['--help'],
      emitStdout: out.add,
      emitStderr: err.add,
    );
    expect(code, 0);
    expect(err, isEmpty);
    expect(out.join('\n'), contains('melos run run_observer_game'));
    expect(out.join('\n'), contains('--output'));
  });

  test('parse failure yields EX_USAGE', () {
    final out = <String>[];
    final err = <String>[];
    final code = runObserverGameCli(
      ['--not-a-flag'],
      emitStdout: out.add,
      emitStderr: err.add,
    );
    expect(code, kExitUsage);
    expect(out, isEmpty);
    expect(err, isNotEmpty);
  });

  test('non-help invokes stub S4 message', () {
    final out = <String>[];
    final err = <String>[];
    final code = runObserverGameCli(
      ['--output', '/tmp/o'],
      emitStdout: out.add,
      emitStderr: err.add,
    );
    expect(code, 2);
    expect(out, isEmpty);
    expect(err.join('\n'), contains('#2498'));
  });
}
