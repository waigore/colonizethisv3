import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _kSpecPath = '../SPEC/ui/components/old-world-race-chip.md';
const String _kComponentsReadmePath = '../SPEC/ui/components/README.md';

void main() {
  suppressLogsForTests();

  test('old-world-race-chip spec exists with required sections', () {
    final body = File(_kSpecPath).readAsStringSync();
    expect(body, contains('# Old World race chip'));
    expect(body, contains('## Widget contract'));
    expect(body, contains('## Acceptance criteria (Given–When–Then)'));
    expect(body, contains('#4451'));
    expect(body, contains('NavigateToRouteEvent'));
    final words = body
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    expect(
      words.length <= 1000,
      isTrue,
      reason: 'word count is ${words.length}',
    );
  });

  test('components README lists the Old World race chip', () {
    final body = File(_kComponentsReadmePath).readAsStringSync();
    expect(body, contains('old-world-race-chip.md'));
  });
}
