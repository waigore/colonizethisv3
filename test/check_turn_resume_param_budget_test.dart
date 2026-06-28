import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_turn_resume_param_budget.dart';

const _wideResumeDeclaration = '''
import 'turn_resolver_config.dart';

TurnResolutionResult resumeTurnResolutionWithOvertureDecisions({
  required Game game,
  required List<OvertureOffer> pendingOvertures,
  required List<OvertureDecision> decisions,
  required MapTopology topology,
  required Orders orders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  GameEventBus? eventBus,
  void Function(DialogueEvent)? onDialogue,
  void Function(GameEvent)? onGameEvent,
  void Function(Map<String, Map<String, int>> byRecipe)? onProductionComplete,
}) {
  return _dispatch();
}
''';

const _configResumeDeclaration = '''
import 'turn_resolver_config.dart';

TurnResolutionResult resumeTurnResolutionWithOvertureDecisions({
  required Game game,
  required List<OvertureOffer> pendingOvertures,
  required List<OvertureDecision> decisions,
  required TurnResolverConfig config,
}) {
  return _dispatch(game: game, config: config, overtureDecisions: decisions);
}

TurnResolutionResult resumeTurnResolutionWithFtpDecisions({
  required Game game,
  required List<FtpDecision> decisions,
  required TurnResolverConfig config,
}) {
  return _dispatch(game: game, config: config, ftpDecisions: decisions);
}
''';

void main() {
  group('runCheckTurnResumeParamBudget', () {
    test('fails for a wide resume declaration in turn lib', () {
      final temp = Directory.systemTemp.createTempSync('turn-resume-wide-');
      try {
        _writeTurnLibFile(temp, 'turn_resolver.dart', _wideResumeDeclaration);

        final errors = <String>[];
        final exitCode = runCheckTurnResumeParamBudget(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        final joined = errors.join('\n');
        expect(joined, contains('turn_resolver.dart:3'));
        expect(joined, contains('resumeTurnResolutionWithOvertureDecisions'));
        expect(joined, contains('14'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes for config-based resume declarations in turn lib', () {
      final temp = Directory.systemTemp.createTempSync('turn-resume-ok-');
      try {
        _writeTurnLibFile(temp, 'turn_resolver.dart', _configResumeDeclaration);

        final exitCode = runCheckTurnResumeParamBudget(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores a wide resume declaration outside the turn lib', () {
      final temp = Directory.systemTemp.createTempSync('turn-resume-other-');
      try {
        final otherLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_logic', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(otherLib.path, 'turn_resolver.dart'),
          _wideResumeDeclaration,
        );

        final exitCode = runCheckTurnResumeParamBudget(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('turnResumeCountNamedParams', () {
    test('counts top-level named parameters', () {
      const sig = '({required Game game, required TurnResolverConfig config})';
      expect(turnResumeCountNamedParams(sig, sig.indexOf('{')), 2);
    });

    test('ignores commas nested in a function-type parameter', () {
      const sig =
          '({required Game game, void Function(int, int)? cb, int? x})';
      expect(turnResumeCountNamedParams(sig, sig.indexOf('{')), 3);
    });

    test('ignores commas nested in generic type arguments', () {
      const sig = '({Map<String, int>? a, List<int>? b, int? c})';
      expect(turnResumeCountNamedParams(sig, sig.indexOf('{')), 3);
    });

    test('does not inflate the count for a trailing comma', () {
      const sig = '({required Game game, required TurnResolverConfig config,})';
      expect(turnResumeCountNamedParams(sig, sig.indexOf('{')), 2);
    });

    test('returns 0 for an empty parameter block', () {
      const sig = '({})';
      expect(turnResumeCountNamedParams(sig, sig.indexOf('{')), 0);
    });
  });

  group('turnResumeParamBudgetPathInScope', () {
    test('matches turn package lib paths only', () {
      expect(
        turnResumeParamBudgetPathInScope(
          'packages/colonizethis_turn/lib/src/turn/turn_resolver.dart',
        ),
        isTrue,
      );
      expect(
        turnResumeParamBudgetPathInScope(
          'packages/colonizethis_logic/lib/src/x.dart',
        ),
        isFalse,
      );
    });
  });
}

void _writeTurnLibFile(Directory temp, String name, String content) {
  final turnLib = Directory(
    p.join(temp.path, 'packages', 'colonizethis_turn', 'lib', 'src', 'turn'),
  )..createSync(recursive: true);
  _writeDartFile(p.join(turnLib.path, name), content);
}

void _writeDartFile(String path, String content) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}
