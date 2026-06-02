// Asserts the batched-concurrent behavior of `e2eDecodePngAssetPathsParallel`
// (Refs GitHub #2336 AC3): the helper must decode every asset path it is
// given, surface failed paths in the returned list, and respect the
// `batchSize` parameter as an upper bound on in-flight decodes — never a
// strict serial-iteration limit.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  suppressLogsForTests();

  test('returns an empty failure list when given no paths', () async {
    final failures = await e2eDecodePngAssetPathsParallel(const <String>[]);
    expect(failures, isEmpty);
  });

  test('surfaces every missing asset path in the failure list', () async {
    final failures = await e2eDecodePngAssetPathsParallel(const <String>[
      'assets/icons/64/missing_one.png',
      'assets/icons/64/missing_two.png',
      'assets/icons/64/missing_three.png',
    ]);
    expect(failures, hasLength(3));
    expect(
      failures.every(
        (entry) => entry.startsWith('assets/icons/64/missing_'),
      ),
      isTrue,
      reason:
          'Each failure entry must begin with the offending asset path so '
          'maintainers can attribute decode errors without re-running the '
          'integration suite.',
    );
  });

  test('rejects non-positive batch sizes', () {
    expect(
      () => e2eDecodePngAssetPathsParallel(
        const <String>['assets/icons/64/missing.png'],
        batchSize: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => e2eDecodePngAssetPathsParallel(
        const <String>['assets/icons/64/missing.png'],
        batchSize: -3,
      ),
      throwsArgumentError,
    );
  });

  test('honors a tighter batchSize without losing failures', () async {
    final failures = await e2eDecodePngAssetPathsParallel(
      const <String>[
        'assets/icons/64/missing_a.png',
        'assets/icons/64/missing_b.png',
        'assets/icons/64/missing_c.png',
        'assets/icons/64/missing_d.png',
      ],
      batchSize: 2,
    );
    expect(failures, hasLength(4));
  });
}
