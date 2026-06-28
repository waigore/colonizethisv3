import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_logic_diplomatic_sub_validator_size.dart';

/// Tests for the `repo.logic_diplomatic_sub_validator_size` repo-lint rule
/// (SPEC/program/orders.md § Diplomatic sub-validators, Refs #2560).
void main() {
  group('check_logic_diplomatic_sub_validator_size', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckLogicDiplomaticSubValidatorSize(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains('no violations found'),
      );
    });

    test(
        'fails when a per-type validator file declares a bespoke '
        '`implements DiplomaticSubValidator` class', () {
      final temp = _seedFakeRepo();
      addTearDown(() => temp.deleteSync(recursive: true));

      final dipDir = _diplomaticDirIn(temp);
      // Sanctioned contract file: a tiny adapter is OK.
      File(p.join(dipDir.path, 'diplomatic_sub_validator.dart')).writeAsStringSync(
        _sanctionedContractFile(),
      );
      // Per-type file declaring a bespoke class — forbidden.
      File(p.join(dipDir.path, 'alliance_validator.dart')).writeAsStringSync(
        _bespokeSubValidatorClass(),
      );

      final err = <String>[];
      final info = <String>[];
      final code = runCheckLogicDiplomaticSubValidatorSize(
        temp.path,
        info: info.add,
        err: err.add,
      );

      expect(code, 1, reason: '${info.join('\n')}\n${err.join('\n')}');
      final allErr = err.join('\n');
      expect(allErr, contains('alliance_validator.dart'));
      expect(
        allErr,
        contains(
          'bespoke `implements DiplomaticSubValidator` classes are forbidden',
        ),
      );
    });

    test(
        'passes when per-type files are free factory functions and only the '
        'contract file holds a small sanctioned adapter', () {
      final temp = _seedFakeRepo();
      addTearDown(() => temp.deleteSync(recursive: true));

      final dipDir = _diplomaticDirIn(temp);
      File(p.join(dipDir.path, 'diplomatic_sub_validator.dart')).writeAsStringSync(
        _sanctionedContractFile(),
      );
      File(p.join(dipDir.path, 'alliance_validator.dart')).writeAsStringSync(
        _factoryFunctionValidatorFile(),
      );

      final info = <String>[];
      final err = <String>[];
      final code = runCheckLogicDiplomaticSubValidatorSize(
        temp.path,
        info: info.add,
        err: err.add,
      );

      expect(code, 0, reason: '${info.join('\n')}\n${err.join('\n')}');
      expect(info.join('\n'), contains('no violations found'));
    });

    test(
        'fails when the sanctioned contract-file adapter exceeds the '
        '30-line body cap', () {
      final temp = _seedFakeRepo();
      addTearDown(() => temp.deleteSync(recursive: true));

      final dipDir = _diplomaticDirIn(temp);
      File(p.join(dipDir.path, 'diplomatic_sub_validator.dart')).writeAsStringSync(
        _oversizedSanctionedAdapter(),
      );

      final err = <String>[];
      final info = <String>[];
      final code = runCheckLogicDiplomaticSubValidatorSize(
        temp.path,
        info: info.add,
        err: err.add,
      );

      expect(code, 1, reason: '${info.join('\n')}\n${err.join('\n')}');
      expect(
        err.join('\n'),
        contains('class body:'),
      );
      expect(err.join('\n'), contains('diplomatic_sub_validator.dart'));
    });

    test('fails when the diplomatic validators directory is missing', () {
      final temp = Directory.systemTemp.createTempSync(
        'logic_diplomatic_sub_validator_size_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final err = <String>[];
      final code = runCheckLogicDiplomaticSubValidatorSize(
        temp.path,
        info: (_) {},
        err: err.add,
      );

      expect(code, 1);
      expect(err.join('\n'), contains('directory not found'));
    });
  });
}

Directory _seedFakeRepo() {
  final temp = Directory.systemTemp.createTempSync(
    'logic_diplomatic_sub_validator_size_',
  );
  _diplomaticDirIn(temp).createSync(recursive: true);
  return temp;
}

Directory _diplomaticDirIn(Directory repo) => Directory(
      p.join(
        repo.path,
        'packages',
        'colonizethis_orders',
        'lib',
        'src',
        'orders',
        'validators',
        'diplomatic',
      ),
    );

String _sanctionedContractFile() => '''
abstract interface class DiplomaticSubValidator {
  ({Object result, int treasury}) validate({
    required Object order,
    required int treasury,
  });
}

final class _DelegatedDiplomaticSubValidator implements DiplomaticSubValidator {
  const _DelegatedDiplomaticSubValidator(this._check);

  final ({Object result, int treasury}) Function({
    required Object order,
    required int treasury,
  }) _check;

  @override
  ({Object result, int treasury}) validate({
    required Object order,
    required int treasury,
  }) => _check(order: order, treasury: treasury);
}
''';

String _oversizedSanctionedAdapter() {
  final buffer = StringBuffer()
    ..writeln('abstract interface class DiplomaticSubValidator {}')
    ..writeln()
    ..writeln(
      'final class _DelegatedDiplomaticSubValidator implements DiplomaticSubValidator {',
    );
  for (var i = 0; i < 40; i++) {
    buffer.writeln('  final Object field$i = const Object();');
  }
  buffer.writeln('}');
  return buffer.toString();
}

String _bespokeSubValidatorClass() => '''
import 'diplomatic_sub_validator.dart';

final class AllianceValidator implements DiplomaticSubValidator {
  const AllianceValidator();

  @override
  ({Object result, int treasury}) validate({
    required Object order,
    required int treasury,
  }) => (result: const Object(), treasury: treasury);
}
''';

String _factoryFunctionValidatorFile() => '''
import 'diplomatic_sub_validator.dart';

DiplomaticSubValidator allianceValidator(Object ctx) =>
    delegatedDiplomaticSubValidator(({
      required Object order,
      required int treasury,
    }) {
      return (result: const Object(), treasury: treasury);
    });
''';
