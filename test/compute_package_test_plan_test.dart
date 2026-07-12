// Unit tests for tool/compute_package_test_plan.py selective plan.
// SPEC/program/test-logging.md — package_tests path gate.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final root = Directory.current.path;
  final script = '$root/tool/compute_package_test_plan.py';

  Future<List<dynamic>> runPlan(List<String> args) async {
    final result = await Process.run('python3', [script, ...args]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    return jsonDecode(result.stdout as String) as List<dynamic>;
  }

  test('no flags defaults to all CORE packages', () async {
    final plan = await runPlan(const []);
    expect(plan, contains('colonizethis_logic'));
    expect(plan, contains('colonizethis_ai'));
    expect(plan, contains('colonizethis_orders'));
    expect(plan.length, greaterThanOrEqualTo(14));
  });

  test('all CORE flags false yields empty plan (CI selective)', () async {
    final plan = await runPlan(const [
      '--changed-models=false',
      '--changed-data=false',
      '--changed-save=false',
      '--changed-map=false',
      '--changed-world=false',
      '--changed-combat=false',
      '--changed-economy=false',
      '--changed-diplomacy=false',
      '--changed-setup=false',
      '--changed-orders=false',
      '--changed-turn=false',
      '--changed-ai_contracts=false',
      '--changed-logic=false',
      '--changed-ai=false',
    ]);
    expect(plan, isEmpty);
  });

  test('orders-only change includes orders in the plan', () async {
    final plan = await runPlan(const [
      '--changed-models=false',
      '--changed-data=false',
      '--changed-save=false',
      '--changed-map=false',
      '--changed-world=false',
      '--changed-combat=false',
      '--changed-economy=false',
      '--changed-diplomacy=false',
      '--changed-setup=false',
      '--changed-orders=true',
      '--changed-turn=false',
      '--changed-ai_contracts=false',
      '--changed-logic=false',
      '--changed-ai=false',
    ]);
    expect(plan, contains('colonizethis_orders'));
    expect(plan, isNot(contains('colonizethis_models')));
  });
}
