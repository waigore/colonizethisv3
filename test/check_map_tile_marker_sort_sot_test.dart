import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_map_tile_marker_sort_sot.dart';

void main() {
  test('passes for the real map view layer', () {
    final logs = <String>[];
    final code = runCheckMapTileMarkerSortSot(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(code, 0, reason: logs.join('\n'));
  });

  test('fails when a view file inlines y/x/tileKey sort', () {
    final temp = Directory.systemTemp.createTempSync('map_tile_sort_sot_');
    addTearDown(() => temp.deleteSync(recursive: true));
    File('${temp.path}/packages/colonizethis_map/lib/src/view/bad_sort.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
void sortBad(List<({int y, int x, String tileKey})> markers) {
  markers.sort((a, b) {
    final yc = a.y.compareTo(b.y);
    if (yc != 0) return yc;
    final xc = a.x.compareTo(b.x);
    if (xc != 0) return xc;
    return a.tileKey.compareTo(b.tileKey);
  });
}
''');

    final logs = <String>[];
    final code = runCheckMapTileMarkerSortSot(
      temp.path,
      info: logs.add,
      err: logs.add,
    );
    expect(code, 1);
    expect(logs.join('\n'), contains('bad_sort.dart'));
  });
}
