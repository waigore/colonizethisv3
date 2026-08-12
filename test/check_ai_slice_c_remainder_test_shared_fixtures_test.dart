import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_build_planner_civilian_scoring_test_shared_fixtures.dart';
import '../tool/check_ai_civilian_build_live_wiring_test_shared_fixtures.dart';
import '../tool/check_ai_develop_nw_purchase_suppression_test_shared_fixtures.dart';
import '../tool/check_ai_diplomacy_planner_boycott_break_subsidy_wiring_test_shared_fixtures.dart';
import '../tool/check_ai_dossier_test_shared_fixtures.dart';
import '../tool/check_ai_expand_feedstock_seller_test_shared_fixtures.dart';
import '../tool/check_ai_expand_phase_planner_focus_minor_target_test_shared_fixtures.dart';
import '../tool/check_ai_faction_query_test_shared_fixtures.dart';
import '../tool/check_ai_growth_stage_industry_counsel_test_shared_fixtures.dart';
import '../tool/check_ai_phase_planner_economy_build_pick_cargo_bonus_test_shared_fixtures.dart';
import '../tool/check_ai_planning_diplomatic_scans_test_shared_fixtures.dart';
import '../tool/check_ai_region_military_destination_filter_test_shared_fixtures.dart';

void main() {
  group('Slice C remainder shared-fixture scanners', () {
    test('build planner civilian scoring fails on local _game', () {
      final temp = Directory.systemTemp.createTempSync('ai-bp-civ-');
      try {
        _writeSupport(
          temp,
          'build_planner_civilian_scoring_test_support.dart',
        );
        _writePlanningAdopter(
          temp,
          'build_planner_civilian_scoring_test.dart',
          'Game _game() => throw UnimplementedError();\n',
        );
        final errors = <String>[];
        expect(
          runCheckAiBuildPlannerCivilianScoringTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          ),
          1,
        );
        expect(errors.join('\n'), contains('_game'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('civilian build live wiring fails on local _gameWithLeader', () {
      final temp = Directory.systemTemp.createTempSync('ai-civ-wire-');
      try {
        _writeSupport(temp, 'civilian_build_live_wiring_test_support.dart');
        _writePlanningAdopter(
          temp,
          'civilian_build_live_wiring_test.dart',
          'Game _gameWithLeader() => throw UnimplementedError();\n',
        );
        final errors = <String>[];
        expect(
          runCheckAiCivilianBuildLiveWiringTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          ),
          1,
        );
        expect(errors.join('\n'), contains('_gameWithLeader'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('focus minor target fails on local _focusMinorGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-focus-minor-');
      try {
        _writeSupport(
          temp,
          'expand_phase_planner_focus_minor_target_test_support.dart',
        );
        _writePlanningAdopter(
          temp,
          'expand_phase_planner_focus_minor_target_early_cases.dart',
          'Game _focusMinorGame() => throw UnimplementedError();\n',
        );
        final errors = <String>[];
        expect(
          runCheckAiExpandPhasePlannerFocusMinorTargetTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          ),
          1,
        );
        expect(errors.join('\n'), contains('focus-minor Game factory'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('faction query fails on local _game in util pin', () {
      final temp = Directory.systemTemp.createTempSync('ai-faction-q-');
      try {
        _writeSupport(temp, 'faction_query_test_support.dart');
        final util = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'util'),
        )..createSync(recursive: true);
        File(p.join(util.path, 'faction_query_test.dart')).writeAsStringSync(
          'Game _game() => throw UnimplementedError();\n',
        );
        final errors = <String>[];
        expect(
          runCheckAiFactionQueryTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          ),
          1,
        );
        expect(errors.join('\n'), contains('_game'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('region military destination filter fails on local _game', () {
      final temp = Directory.systemTemp.createTempSync('ai-reg-mil-');
      try {
        _writeSupport(
          temp,
          'region_military_destination_filter_test_support.dart',
        );
        _writePlanningAdopter(
          temp,
          'region_military_destination_filter_test.dart',
          'Game _game() => throw UnimplementedError();\n',
        );
        final errors = <String>[];
        expect(
          runCheckAiRegionMilitaryDestinationFilterTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          ),
          1,
        );
        expect(errors.join('\n'), contains('_game'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('planning diplomatic scans fails on local _gameWithEvents', () {
      final temp = Directory.systemTemp.createTempSync('ai-dip-scan-');
      try {
        _writeSupport(temp, 'planning_diplomatic_scans_test_support.dart');
        _writePlanningAdopter(
          temp,
          'planning_diplomatic_scans_test.dart',
          'Game _gameWithEvents(List x) => throw UnimplementedError();\n',
        );
        final errors = <String>[];
        expect(
          runCheckAiPlanningDiplomaticScansTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          ),
          1,
        );
        expect(errors.join('\n'), contains('_gameWithEvents'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('dossier pin fails on local _gameWithEvidence', () {
      final temp = Directory.systemTemp.createTempSync('ai-dossier-');
      try {
        _writeSupport(temp, 'dossier_test_support.dart');
        final perception = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'perception'),
        )..createSync(recursive: true);
        File(p.join(perception.path, 'dossier_test.dart')).writeAsStringSync(
          'Game _gameWithEvidence(List x) => throw UnimplementedError();\n',
        );
        final errors = <String>[];
        expect(
          runCheckAiDossierTestSharedFixtures(
            temp.path,
            info: (_) {},
            err: errors.add,
          ),
          1,
        );
        expect(errors.join('\n'), contains('_gameWithEvidence'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}

void _writeSupport(Directory temp, String name) {
  final support = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'support'),
  )..createSync(recursive: true);
  File(p.join(support.path, name)).writeAsStringSync('// stub\n');
}

void _writePlanningAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
