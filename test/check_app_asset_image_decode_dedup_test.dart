// Refs #3699 — guards `repo.app_asset_image_decode_dedup` enforcement.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_asset_image_decode_dedup.dart';

void main() {
  group('repo.app_asset_image_decode_dedup', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAppAssetImageDecodeDedup(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains(
          'check_app_asset_image_decode_dedup: `decodeImageFromList` is '
          'confined to',
        ),
      );
    });

    test(
      'fails when a non-helper file inlines decodeImageFromList',
      () {
        final temp = Directory.systemTemp.createTempSync('decode_dedup_fail_');
        addTearDown(() => temp.deleteSync(recursive: true));

        final flameDir = _flameDir(temp);
        File(p.join(flameDir.path, 'foo_tileset.dart')).writeAsStringSync(
          "import 'dart:ui' as ui;\n"
          'Future<void> loadFoo(Object bytes) async {\n'
          '  ui.decodeImageFromList(bytes as dynamic, (img) {});\n'
          '}\n',
        );

        final errLogs = <String>[];
        final code = runCheckAppAssetImageDecodeDedup(
          temp.path,
          info: (_) {},
          err: errLogs.add,
        );

        expect(code, 1);
        expect(errLogs.join('\n'), contains('foo_tileset.dart'));
        expect(errLogs.join('\n'), contains('decodeImageFromList'));
      },
    );

    test('fails when an icon cache omits `extends AssetImageCache`', () {
      final temp = Directory.systemTemp.createTempSync('decode_dedup_cache_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final flameDir = _flameDir(temp);
      File(p.join(flameDir.path, 'widget_icon_cache.dart')).writeAsStringSync(
        'class WidgetIconCache {\n'
        '  WidgetIconCache();\n'
        '}\n',
      );

      final errLogs = <String>[];
      final code = runCheckAppAssetImageDecodeDedup(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains('widget_icon_cache.dart'));
      expect(errLogs.join('\n'), contains('WidgetIconCache'));
      expect(errLogs.join('\n'), contains('AssetImageCache'));
    });

    test(
      'passes when caches extend the base and decode stays in the helper',
      () {
        final temp = Directory.systemTemp.createTempSync('decode_dedup_pass_');
        addTearDown(() => temp.deleteSync(recursive: true));

        final flameDir = _flameDir(temp);
        File(p.join(flameDir.path, 'asset_image_cache.dart')).writeAsStringSync(
          "import 'dart:ui' as ui;\n"
          'Future<ui.Image> decodeImageAsset(String path) async {\n'
          '  return ui.decodeImageFromList(const [], (img) {}) as dynamic;\n'
          '}\n'
          'abstract class AssetImageCache {}\n',
        );
        File(p.join(flameDir.path, 'widget_icon_cache.dart')).writeAsStringSync(
          'class WidgetIconCache extends AssetImageCache {\n'
          '  WidgetIconCache();\n'
          '}\n',
        );

        final code = runCheckAppAssetImageDecodeDedup(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(code, 0);
      },
    );

    test('exempts the AssetImageCache base and non-cache classes', () {
      final temp = Directory.systemTemp.createTempSync('decode_dedup_base_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final flameDir = _flameDir(temp);
      // Base lives in asset_image_cache.dart (not a `*_icon_cache.dart` file)
      // and may declare decodeImageFromList; a sibling non-cache class must not
      // be required to extend the base.
      File(p.join(flameDir.path, 'asset_image_cache.dart')).writeAsStringSync(
        "import 'dart:ui' as ui;\n"
        'Future<ui.Image> decodeImageAsset(String path) async {\n'
        '  return ui.decodeImageFromList(const [], (img) {}) as dynamic;\n'
        '}\n'
        'abstract class AssetImageCache {}\n',
      );
      File(p.join(flameDir.path, 'transport_overlay_tileset.dart'))
          .writeAsStringSync(
            'class TransportOverlayTileset {\n'
            '  TransportOverlayTileset();\n'
            '}\n',
          );

      final code = runCheckAppAssetImageDecodeDedup(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}

Directory _flameDir(Directory temp) {
  return Directory(p.join(temp.path, 'app/lib/features/game/flame'))
    ..createSync(recursive: true);
}
