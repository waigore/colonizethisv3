import 'package:test/test.dart';

import '../tool/check_disallowed_ast_patterns.dart';
import 'disallowed_ast_patterns_test_yaml_fixture.dart';

const _kRuleId = 'nested_world_state_copywith';
const _kLogicPath = 'packages/colonizethis_logic/lib/src/world/x.dart';
const _kLogicLibPath = 'packages/colonizethis_logic/lib/some/x.dart';
const _kOutsidePath = 'app/lib/widgets/x.dart';

Iterable<DisallowedAstViolation> _nestedCopyWithViolations(
  String path,
  String src,
  List<DisallowedPatternRule> rules,
) =>
    findDisallowedAstViolations(path, src, rules)
        .where((e) => e.ruleId == _kRuleId);

void main() {
  late List<DisallowedPatternRule> rules;

  setUp(() {
    rules = loadDisallowedAstRulesForTest(disallowedAstPatternsTestYaml);
  });

  group('nested_world_state_copywith', () {
    test(
      'flags 3-level chain '
      'game.copyWith(worldState: ws.copyWith(oldWorld: ow.copyWith(...)))',
      () {
        const src = r'''
class OldWorld { OldWorld copyWith({int? units}) => this; }
class WorldState { WorldState copyWith({OldWorld? oldWorld}) => this; }
class Game { Game copyWith({WorldState? worldState}) => this; }
Game bad(Game game, WorldState ws, OldWorld ow) {
  return game.copyWith(
    worldState: ws.copyWith(
      oldWorld: ow.copyWith(units: 1),
    ),
  );
}
''';
        expect(_nestedCopyWithViolations(_kLogicPath, src, rules), isNotEmpty);
      },
    );

    test(
      'flags 3-level chain inside parenthesized inner expression',
      () {
        const src = r'''
class OldWorld { OldWorld copyWith({int? units}) => this; }
class WorldState { WorldState copyWith({OldWorld? oldWorld}) => this; }
class Game { Game copyWith({WorldState? worldState}) => this; }
Game bad(Game game, WorldState ws, OldWorld ow) {
  return game.copyWith(
    worldState: (ws.copyWith(
      oldWorld: (ow.copyWith(units: 1)),
    )),
  );
}
''';
        expect(_nestedCopyWithViolations(_kLogicPath, src, rules), isNotEmpty);
      },
    );

    test(
      'flags 3-level chain with non-worldState inner arg label '
      '(turnState path)',
      () {
        const src = r'''
class TurnState { TurnState copyWith({int? turn}) => this; }
class WorldState { WorldState copyWith({TurnState? turnState}) => this; }
class Game { Game copyWith({WorldState? worldState}) => this; }
Game bad(Game game, WorldState ws, TurnState ts) {
  return game.copyWith(
    worldState: ws.copyWith(
      turnState: ts.copyWith(turn: 12),
    ),
  );
}
''';
        expect(_nestedCopyWithViolations(_kLogicPath, src, rules), isNotEmpty);
      },
    );

    test('allows 2-level shallow copyWith chain', () {
      const src = r'''
class WorldState { WorldState copyWith({int? turn}) => this; }
class Game { Game copyWith({WorldState? worldState}) => this; }
Game ok(Game game, WorldState ws) {
  return game.copyWith(worldState: ws.copyWith(turn: 1));
}
''';
      expect(_nestedCopyWithViolations(_kLogicPath, src, rules), isEmpty);
    });

    test(
      'allows updateWorldState-style escape hatch '
      '(outer copyWith with function-call inner)',
      () {
        const src = r'''
class WorldState {}
class Game { Game copyWith({WorldState? worldState}) => this; }
WorldState mutate(WorldState ws) => ws;
Game ok(Game game, WorldState ws) {
  return game.copyWith(worldState: mutate(ws));
}
''';
        expect(_nestedCopyWithViolations(_kLogicLibPath, src, rules), isEmpty);
      },
    );

    test('ignores outer copyWith without worldState named argument', () {
      const src = r'''
class Inner { Inner copyWith({int? a}) => this; }
class Outer { Outer copyWith({Inner? other}) => this; }
class Holder { Holder copyWith({Outer? wrapped}) => this; }
Holder ok(Holder h, Outer outer, Inner inner) {
  return h.copyWith(
    wrapped: outer.copyWith(
      other: inner.copyWith(a: 1),
    ),
  );
}
''';
      expect(_nestedCopyWithViolations(_kLogicPath, src, rules), isEmpty);
    });

    test(
      'ignores chain whose level-3 sits inside a list literal '
      '(structural mismatch, not a direct named-arg copyWith)',
      () {
        const src = r'''
class Player { Player copyWith({int? score}) => this; }
class WorldState {
  WorldState copyWith({List<Player>? updatedPlayers}) => this;
}
class Game { Game copyWith({WorldState? worldState}) => this; }
Game ok(Game game, WorldState ws, Player player) {
  return game.copyWith(
    worldState: ws.copyWith(
      updatedPlayers: [player.copyWith(score: 1)],
    ),
  );
}
''';
        expect(_nestedCopyWithViolations(_kLogicPath, src, rules), isEmpty);
      },
    );

    test('ignores 3-level chain outside scoped path prefix', () {
      const src = r'''
class OldWorld { OldWorld copyWith({int? units}) => this; }
class WorldState { WorldState copyWith({OldWorld? oldWorld}) => this; }
class Game { Game copyWith({WorldState? worldState}) => this; }
Game stillOk(Game game, WorldState ws, OldWorld ow) {
  return game.copyWith(
    worldState: ws.copyWith(
      oldWorld: ow.copyWith(units: 1),
    ),
  );
}
''';
      expect(_nestedCopyWithViolations(_kOutsidePath, src, rules), isEmpty);
    });

    test('respects same-line ignore for nested_world_state_copywith', () {
      const src = r'''
class OldWorld { OldWorld copyWith({int? units}) => this; }
class WorldState { WorldState copyWith({OldWorld? oldWorld}) => this; }
class Game { Game copyWith({WorldState? worldState}) => this; }
Game tolerated(Game game, WorldState ws, OldWorld ow) {
  return game.copyWith(worldState: ws.copyWith(oldWorld: ow.copyWith(units: 1))); // ignore: disallowed_ast_nested_world_state_copywith
}
''';
      expect(_nestedCopyWithViolations(_kLogicPath, src, rules), isEmpty);
    });

    test('respects ignore comment on previous line', () {
      const src = r'''
class OldWorld { OldWorld copyWith({int? units}) => this; }
class WorldState { WorldState copyWith({OldWorld? oldWorld}) => this; }
class Game { Game copyWith({WorldState? worldState}) => this; }
Game tolerated(Game game, WorldState ws, OldWorld ow) {
  // ignore: disallowed_ast_nested_world_state_copywith
  return game.copyWith(worldState: ws.copyWith(oldWorld: ow.copyWith(units: 1)));
}
''';
      expect(_nestedCopyWithViolations(_kLogicPath, src, rules), isEmpty);
    });

    test('respects file-level ignore_for_file marker', () {
      const src = r'''
// ignore_for_file: disallowed_ast_nested_world_state_copywith
class OldWorld { OldWorld copyWith({int? units}) => this; }
class WorldState { WorldState copyWith({OldWorld? oldWorld}) => this; }
class Game { Game copyWith({WorldState? worldState}) => this; }
Game tolerated(Game game, WorldState ws, OldWorld ow) {
  return game.copyWith(
    worldState: ws.copyWith(
      oldWorld: ow.copyWith(units: 1),
    ),
  );
}
''';
      expect(_nestedCopyWithViolations(_kLogicPath, src, rules), isEmpty);
    });
  });
}
