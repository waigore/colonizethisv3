import 'package:test/test.dart';

import '../tool/check_setup_helpers_first_class_libraries.dart';

void main() {
  group('findSetupHelpersFirstClassLibraryViolations', () {
    const helpers =
        'packages/colonizethis_setup/lib/src/setup/game_setup_helpers.dart';
    const towns =
        'packages/colonizethis_setup/lib/src/setup/game_setup_helpers_towns.dart';
    const naming =
        'packages/colonizethis_setup/lib/src/setup/'
        'game_setup_helpers_naming.dart';
    const bootstrap =
        'packages/colonizethis_setup/lib/src/setup/'
        'game_setup_helpers_bootstrap.dart';

    Map<String, String> cleanTree() => {
      helpers: '''
export 'game_setup_helpers_bootstrap.dart';
export 'game_setup_helpers_naming.dart';
export 'game_setup_helpers_towns.dart';
''',
      towns: 'Game assignProvinceTowns() => throw UnimplementedError();\n',
      naming: 'Game applyNaming() => throw UnimplementedError();\n',
      bootstrap: 'Game addStartingUnits() => throw UnimplementedError();\n',
    };

    test('passes when libraries are first-class and barrel-exported', () {
      final violations = findSetupHelpersFirstClassLibraryViolations(
        sourcesByPath: cleanTree(),
      );
      expect(violations, isEmpty);
    });

    test('flags naming when it is still a part-of fragment', () {
      final sources = cleanTree();
      sources[naming] = "part of 'game_setup_helpers.dart';\nGame applyNaming() => throw UnimplementedError();\n";
      final violations = findSetupHelpersFirstClassLibraryViolations(
        sourcesByPath: sources,
      );
      expect(violations, isNotEmpty);
      expect(
        violations.any(
          (v) =>
              v.path == naming && v.message.contains('first-class library'),
        ),
        isTrue,
      );
    });

    test('flags barrel part directive instead of export', () {
      final sources = cleanTree();
      sources[helpers] = '''
export 'game_setup_helpers_towns.dart';
part 'game_setup_helpers_naming.dart';
export 'game_setup_helpers_bootstrap.dart';
''';
      final violations = findSetupHelpersFirstClassLibraryViolations(
        sourcesByPath: sources,
      );
      expect(violations, isNotEmpty);
      expect(
        violations.any(
          (v) =>
              v.path == helpers &&
              v.message.contains('game_setup_helpers_naming.dart'),
        ),
        isTrue,
      );
    });

    test('flags missing barrel export', () {
      final sources = cleanTree();
      sources[helpers] = '''
export 'game_setup_helpers_towns.dart';
export 'game_setup_helpers_naming.dart';
''';
      final violations = findSetupHelpersFirstClassLibraryViolations(
        sourcesByPath: sources,
      );
      expect(violations, isNotEmpty);
      expect(
        violations.any(
          (v) => v.message.contains('game_setup_helpers_bootstrap.dart'),
        ),
        isTrue,
      );
    });
  });
}
