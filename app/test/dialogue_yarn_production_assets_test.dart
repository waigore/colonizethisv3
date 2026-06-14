import 'dart:io';

import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:jenny/jenny.dart';

/// Locks the production Yarn assets against the parse-time `NameError` that
/// blocked the game at init (#3463). Jenny resolves `{$var}` interpolation when
/// the project is parsed, so every interpolated variable must be `$`-prefixed
/// and defined before `parse`. These tests read the real assets from disk so a
/// regression in the asset (new `{$var}`) or in the binding contract fails CI.
void main() {
  suppressLogsForTests();

  String readAsset(String relativePath) {
    final file = File(relativePath);
    expect(
      file.existsSync(),
      isTrue,
      reason: 'missing production Yarn asset: $relativePath',
    );
    return file.readAsStringSync();
  }

  test(
    'AC-3: production tribe_first_contact.yarn parses with \$-bound variables',
    () {
      final text = readAsset(kDialogueTribeFirstContactAsset);
      final project = YarnProject();
      project.variables.setVariable(r'$tribeName', 'Maya');
      project.variables.setVariable(r'$capitalName', 'Chichen Itza');

      expect(() => project.parse(text), returnsNormally);
      expect(project.nodes.containsKey('tribe_first_contact'), isTrue);
    },
  );

  test(
    'AC-4: production intervention.yarn parses with \$-bound faction variables',
    () {
      final text = readAsset(kDialogueInterventionAsset);
      final project = YarnProject();
      project.variables.setVariable(r'$aggressorName', 'Castile');
      project.variables.setVariable(r'$defenderName', 'Powhatan');
      project.variables.setVariable(r'$interveningName', 'England');

      expect(() => project.parse(text), returnsNormally);
      for (final node in const [
        'DialoguePoint/intervention_intro',
        'DialoguePoint/intervention_situation',
        'DialoguePoint/intervention_reaction_intervene',
        'DialoguePoint/intervention_reaction_do_nothing',
        'DialoguePoint/intervention_reaction_protest',
      ]) {
        expect(
          project.nodes.containsKey(node),
          isTrue,
          reason: 'intervention.yarn missing node "$node"',
        );
      }
    },
  );

  test(
    'negative: parsing tribe_first_contact.yarn without bindings throws NameError',
    () {
      final text = readAsset(kDialogueTribeFirstContactAsset);
      final project = YarnProject();
      expect(() => project.parse(text), throwsA(isA<NameError>()));
    },
  );
}
