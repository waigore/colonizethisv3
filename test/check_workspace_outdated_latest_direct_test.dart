import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_workspace_outdated_latest_direct.dart';

void main() {
  test('passes when direct dependencies are already at latest', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_workspace_outdated_latest_direct_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _createWorkspaceRoots(temp.path);

    final calls = <String>[];
    final code = runCheckWorkspaceOutdatedLatestDirect(
      temp.path,
      processRunner: (exe, args, {workingDirectory}) {
        calls.add('$exe ${args.join(' ')} @${workingDirectory ?? ''}');
        return ProcessResult(
          1,
          0,
          _outdatedJson([
            _pkg(
              package: 'direct_ok',
              kind: 'direct',
              current: '1.2.0',
              resolvable: '1.2.0',
              latest: '1.2.0',
            ),
            _pkg(
              package: 'transitive_ignored',
              kind: 'transitive',
              current: '4.0.0',
              resolvable: '4.1.0',
              latest: '4.1.0',
            ),
          ]),
          '',
        );
      },
    );

    expect(code, 0);
    expect(calls, hasLength(5));
    expect(
      calls,
      contains('dart pub outdated --json @${temp.path}/packages/example_pure_dart'),
    );
  });

  test('fails when direct dependency is below latest and latest is resolvable', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_workspace_outdated_latest_direct_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _createWorkspaceRoots(temp.path);

    final logs = <String>[];
    final code = runCheckWorkspaceOutdatedLatestDirect(
      temp.path,
      info: logs.add,
      err: logs.add,
      processRunner: (exe, args, {workingDirectory}) {
        if ((workingDirectory ?? '').endsWith('/ctdev')) {
          return ProcessResult(
            1,
            0,
            _outdatedJson([
              _pkg(
                package: 'stale_direct',
                kind: 'direct',
                current: '3.0.0',
                resolvable: '3.2.0',
                latest: '3.2.0',
              ),
            ]),
            '',
          );
        }
        return ProcessResult(
          1,
          0,
          _outdatedJson([
            _pkg(
              package: 'ok_direct',
              kind: 'direct',
              current: '1.0.0',
              resolvable: '1.0.0',
              latest: '1.0.0',
            ),
          ]),
          '',
        );
      },
    );

    expect(code, 1);
    final joined = logs.join('\n');
    expect(joined, contains('[ctdev] stale_direct'));
    expect(joined, contains('current=3.0.0 latest=3.2.0'));
  });

  test('passes when latest is not yet resolvable for direct dependency', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_workspace_outdated_latest_direct_blocked_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _createWorkspaceRoots(temp.path);

    final code = runCheckWorkspaceOutdatedLatestDirect(
      temp.path,
      processRunner: (exe, args, {workingDirectory}) {
        return ProcessResult(
          1,
          0,
          _outdatedJson([
            _pkg(
              package: 'blocked_direct',
              kind: 'direct',
              current: '2.0.0',
              resolvable: '2.1.0',
              latest: '3.0.0',
            ),
          ]),
          '',
        );
      },
    );

    expect(code, 0);
  });

  test('ignores explicitly excluded direct dependencies', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_workspace_outdated_latest_direct_excluded_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _createWorkspaceRoots(temp.path);

    final code = runCheckWorkspaceOutdatedLatestDirect(
      temp.path,
      excludedPackages: {'stale_direct'},
      processRunner: (exe, args, {workingDirectory}) {
        return ProcessResult(
          1,
          0,
          _outdatedJson([
            _pkg(
              package: 'stale_direct',
              kind: 'direct',
              current: '1.0.0',
              resolvable: '1.2.0',
              latest: '1.2.0',
            ),
          ]),
          '',
        );
      },
    );

    expect(code, 0);
  });
}

void _createWorkspaceRoots(String root) {
  File('$root/pubspec.yaml').writeAsStringSync('''
name: temp_repo
workspace:
  - app
  - ctdev
  - widgetbook_host
  - packages/example_pure_dart
''');
  Directory('$root/app').createSync(recursive: true);
  File('$root/app/pubspec.yaml').writeAsStringSync('''
name: app
dependencies:
  flutter:
    sdk: flutter
''');
  Directory('$root/ctdev').createSync(recursive: true);
  File('$root/ctdev/pubspec.yaml').writeAsStringSync('''
name: ctdev
dependencies:
  flutter:
    sdk: flutter
''');
  Directory('$root/widgetbook_host').createSync(recursive: true);
  File('$root/widgetbook_host/pubspec.yaml').writeAsStringSync('''
name: widgetbook_host
dependencies:
  flutter:
    sdk: flutter
''');
  Directory('$root/packages/example_pure_dart').createSync(recursive: true);
  File('$root/packages/example_pure_dart/pubspec.yaml').writeAsStringSync('''
name: example_pure_dart
environment:
  sdk: ^3.9.0
''');
}

Map<String, Object?> _pkg({
  required String package,
  required String kind,
  required String current,
  required String resolvable,
  required String latest,
}) {
  return {
    'package': package,
    'kind': kind,
    'current': {'version': current},
    'resolvable': {'version': resolvable},
    'latest': {'version': latest},
  };
}

String _outdatedJson(List<Map<String, Object?>> packages) {
  return jsonEncode({'packages': packages});
}
