import 'package:colonizethis_test/test.dart';
import 'dart:async';

import 'package:colonizethis_models/stream_where_type.dart';

void main() {
  test('whereType emits only elements that are T', () async {
    final out = await Stream<num>.fromIterable([
      1,
      2.5,
      3,
    ]).whereType<int>().toList();
    expect(out, [1, 3]);
  });
}
