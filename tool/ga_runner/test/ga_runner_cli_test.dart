import 'package:colonizethis_test/test.dart';

import 'package:ga_runner/ga_runner_cli.dart';

void main() {
  group('ga_runner CLI', () {
    test('--help prints usage', () async {
      final out = <String>[];
      final code = await runGaRunnerCli(
        <String>['--help'],
        emitStdout: out.add,
        emitStderr: (_) {},
      );
      expect(code, 0);
      expect(out.join('\n'), contains('melos run ga_runner'));
      expect(out.join('\n'), contains('--config'));
      expect(out.join('\n'), contains('--resume'));
    });

    test('requires exactly one of --config or --resume', () async {
      final err = <String>[];
      final code = await runGaRunnerCli(
        <String>[],
        emitStdout: (_) {},
        emitStderr: err.add,
      );
      expect(code, 64);
      expect(err.join('\n'), contains('exactly one'));
    });
  });
}
