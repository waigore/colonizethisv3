// Smoke tests for shared Yarn test fixtures (Refs #3952).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'yarn_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  test('YarnStringAssetBundle returns mapped yarn and throws on miss', () async {
    final bundle = YarnStringAssetBundle({
      'a.yarn': kYarnGameStartIntroShort,
    });
    expect(await bundle.loadString('a.yarn'), contains('game_start_intro'));
    expect(
      () => bundle.loadString('missing.yarn'),
      throwsA(isA<Exception>()),
    );
  });

  test('YarnInlineAssetBundle returns the same text for any key', () async {
    final bundle = YarnInlineAssetBundle(kYarnTraceStory);
    expect(await bundle.loadString('any'), contains('trace_story'));
    expect(await bundle.loadString('other'), contains('First line'));
  });

  test('YarnThrowingAssetBundle fails loadString', () async {
    final bundle = YarnThrowingAssetBundle(
      error: StateError('missing intervention yarn'),
    );
    expect(
      () => bundle.loadString('x.yarn'),
      throwsA(isA<StateError>()),
    );
  });

  test('YarnMissingNodeAssetBundle lacks intro title', () async {
    final bundle = YarnMissingNodeAssetBundle();
    final text = await bundle.loadString('x.yarn');
    expect(text, contains('not_the_intro'));
    expect(text, isNot(contains('game_start_intro')));
  });
}
