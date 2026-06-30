import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_expand_peace_decider_registry.dart';

/// A minimal compliant registry host: declares the typedef, both ordered
/// registry constants, and folds each via `for (final decider in <registry>)`.
const String _compliantHost =
    '''
typedef ExpandPeaceDecider =
    Iterable<String> Function({required Game game, required Snap snapshot});

const List<ExpandPeaceDecider> kSurvivalGreatPowerPeaceDeciders =
    <ExpandPeaceDecider>[alphaPeaceTargets, betaPeaceTargets];

const List<ExpandPeaceDecider> kExpandRatchetGreatPowerPeaceDeciders =
    <ExpandPeaceDecider>[gammaPeaceTargets];

Iterable<String> survivalGreatPowerPeaceTargets({
  required Game game,
  required Snap snapshot,
}) sync* {
  for (final decider in kSurvivalGreatPowerPeaceDeciders) {
    yield* decider(game: game, snapshot: snapshot);
  }
}

Iterable<String> expandRatchetGreatPowerPeaceTargets({
  required Game game,
  required Snap snapshot,
}) sync* {
  for (final decider in kExpandRatchetGreatPowerPeaceDeciders) {
    yield* decider(game: game, snapshot: snapshot);
  }
}
''';

/// A host that re-inlines a hand-unrolled decider chain in one aggregator,
/// dropping the registry fold for the ratchet registry.
const String _handUnrolledHost =
    '''
typedef ExpandPeaceDecider =
    Iterable<String> Function({required Game game, required Snap snapshot});

const List<ExpandPeaceDecider> kSurvivalGreatPowerPeaceDeciders =
    <ExpandPeaceDecider>[alphaPeaceTargets];

const List<ExpandPeaceDecider> kExpandRatchetGreatPowerPeaceDeciders =
    <ExpandPeaceDecider>[gammaPeaceTargets];

Iterable<String> survivalGreatPowerPeaceTargets({
  required Game game,
  required Snap snapshot,
}) sync* {
  for (final decider in kSurvivalGreatPowerPeaceDeciders) {
    yield* decider(game: game, snapshot: snapshot);
  }
}

Iterable<String> expandRatchetGreatPowerPeaceTargets({
  required Game game,
  required Snap snapshot,
}) sync* {
  yield* gammaPeaceTargets(game: game, snapshot: snapshot);
}
''';

void main() {
  group('expandPeaceDeciderRegistryViolations', () {
    test('passes for the live registry host file', () {
      final host = File(
        p.join(
          Directory.current.path,
          expandPeaceDeciderRegistryHostFile.replaceAll('/', p.separator),
        ),
      );
      expect(host.existsSync(), isTrue);
      expect(
        expandPeaceDeciderRegistryViolations(host.readAsStringSync()),
        isEmpty,
      );
    });

    test('passes for a minimal compliant host', () {
      expect(expandPeaceDeciderRegistryViolations(_compliantHost), isEmpty);
    });

    test('flags a hand-unrolled yield* decider chain', () {
      final violations = expandPeaceDeciderRegistryViolations(
        _handUnrolledHost,
      );
      expect(violations, isNotEmpty);
      expect(
        violations.join('\n'),
        contains('hand-unrolled `yield* gammaPeaceTargets(...)`'),
      );
      expect(
        violations.join('\n'),
        contains('for (final decider in kExpandRatchetGreatPowerPeaceDeciders)'),
      );
    });

    test('flags a missing typedef', () {
      final content = _compliantHost.replaceAll(
        'typedef ExpandPeaceDecider',
        'typedef SomethingElse',
      );
      expect(
        expandPeaceDeciderRegistryViolations(content).join('\n'),
        contains('typedef ExpandPeaceDecider'),
      );
    });

    test('flags a missing registry constant', () {
      final content = _compliantHost.replaceAll(
        'const List<ExpandPeaceDecider> kSurvivalGreatPowerPeaceDeciders',
        'const List<ExpandPeaceDecider> kRenamedDeciders',
      );
      expect(
        expandPeaceDeciderRegistryViolations(content).join('\n'),
        contains('kSurvivalGreatPowerPeaceDeciders'),
      );
    });

    test('does not flag yield*/registry mentions inside line comments', () {
      const commented =
          '$_compliantHost\n'
          '/// Doc: do not yield* fooPeaceTargets(...) directly; use the\n'
          '/// registry kSurvivalGreatPowerPeaceDeciders instead.\n';
      expect(expandPeaceDeciderRegistryViolations(commented), isEmpty);
    });
  });

  group('runCheckAiExpandPeaceDeciderRegistry', () {
    test('exit 0 against the real repository', () {
      final exitCode = runCheckAiExpandPeaceDeciderRegistry(
        Directory.current.path,
        info: (_) {},
        err: (_) {},
      );
      expect(exitCode, 0);
    });

    test('exit 0 for a synthetic compliant host tree', () {
      _withTempHost(_compliantHost, (root) {
        final errors = <String>[];
        final exitCode = runCheckAiExpandPeaceDeciderRegistry(
          root,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 0, reason: errors.join('\n'));
      });
    });

    test('exit 1 for a synthetic hand-unrolled host tree', () {
      _withTempHost(_handUnrolledHost, (root) {
        final errors = <String>[];
        final exitCode = runCheckAiExpandPeaceDeciderRegistry(
          root,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('gammaPeaceTargets'));
      });
    });

    test('exit 1 when the registry host file is missing', () {
      final temp = Directory.systemTemp.createTempSync('ai-expand-peace-none-');
      try {
        final errors = <String>[];
        final exitCode = runCheckAiExpandPeaceDeciderRegistry(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('registry host file missing'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}

void _withTempHost(String hostContent, void Function(String root) body) {
  final temp = Directory.systemTemp.createTempSync('ai-expand-peace-');
  try {
    final hostFile = File(
      p.join(
        temp.path,
        expandPeaceDeciderRegistryHostFile.replaceAll('/', p.separator),
      ),
    )..createSync(recursive: true);
    hostFile.writeAsStringSync(hostContent);
    body(temp.path);
  } finally {
    temp.deleteSync(recursive: true);
  }
}
