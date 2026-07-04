import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_event_handler_part_size.dart';

void main() {
  final repoRoot = p.normalize(p.join(Directory.current.path));

  test('app_event_handler_scope part files stay within 500 non-comment lines', () {
    expect(runCheckAppEventHandlerPartSize(repoRoot), 0);
  });
}
