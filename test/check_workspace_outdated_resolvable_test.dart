import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_workspace_outdated_resolvable.dart';

void main() {
  test('passes when every package current equals resolvable', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_workspace_outdated_resolvable_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _createWorkspaceRoots(temp.path);

    final calls = <String>[];
    final code = runCheckWorkspaceOutdatedResolvable(
      temp.path,
      processRunner: (exe, args, {workingDirectory}) {
        calls.add('$exe ${args.join(' ')} @${workingDirectory ?? ''}');
        return ProcessResult(1, 0, _outdatedJson('1.0.0', '1.0.0'), '');
      },
    );

    expect(code, 0);
    expect(calls, hasLength(4));
  });

  test('fails when a package is below resolvable', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_workspace_outdated_resolvable_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _createWorkspaceRoots(temp.path);

    final logs = <String>[];
    final code = runCheckWorkspaceOutdatedResolvable(
      temp.path,
      info: logs.add,
      err: logs.add,
      processRunner: (exe, args, {workingDirectory}) {
        if ((workingDirectory ?? '').endsWith('/app')) {
          return ProcessResult(1, 0, _outdatedJson('1.0.0', '1.2.0'), '');
        }
        return ProcessResult(1, 0, _outdatedJson('1.0.0', '1.0.0'), '');
      },
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('[app]'));
    expect(logs.join('\n'), contains('current=1.0.0 resolvable=1.2.0'));
  });

  test('fails when outdated command exits non-zero', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_workspace_outdated_resolvable_cmdfail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _createWorkspaceRoots(temp.path);

    final logs = <String>[];
    final code = runCheckWorkspaceOutdatedResolvable(
      temp.path,
      info: logs.add,
      err: logs.add,
      processRunner: (exe, args, {workingDirectory}) {
        return ProcessResult(1, 1, '', 'network unavailable');
      },
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('failed in repo root'));
    expect(logs.join('\n'), contains('network unavailable'));
  });
}

void _createWorkspaceRoots(String root) {
  Directory('$root/app').createSync(recursive: true);
  Directory('$root/ctdev').createSync(recursive: true);
  Directory('$root/widgetbook_host').createSync(recursive: true);
}

String _outdatedJson(String current, String resolvable) {
  return jsonEncode({
    'packages': [
      {
        'package': 'example_pkg',
        'current': {'version': current},
        'resolvable': {'version': resolvable},
      },
    ],
  });
}
