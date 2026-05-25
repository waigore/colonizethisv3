// ignore_for_file: avoid_print
import 'dart:io';

/// Compliance checker for `SPEC/ui/*.md` screen specs against the
/// 9-section UI documentation template defined in
/// `.cursor/rules/colonizethis-ui-documentation.mdc`.
///
/// Implements the section-presence rubric from issue #2784 verbatim:
///
/// 1. Header block: file's first non-blank content under the H1 title
///    contains three bold-prefixed lines matching `**Screen ID:**`,
///    `**SPEC/ui**`, and `**Widgetbook:**`.
/// 2. Widget contract: H2 `## Widget contract`.
/// 3. Trigger conditions: H2 matching one of `Trigger conditions`,
///    `Triggers`, `Trigger`, `Access`, `Panel placement and opening`.
/// 4. Layout / wireframe: H2 matching one of `Layout / wireframe`,
///    `Layout`, `Wireframe`, `Wireframe (conceptual)`.
/// 5. Behavior (complete iff Behavior H2 + both `Incoming` and
///    `User actions → outcomes` H3 subsections are present): H2
///    matching one of `Behavior`, `Behaviour`, `Actions`, `User actions`.
/// 6. States and variants: H2 matching one of `States and variants`,
///    `States`, `Variants`.
/// 7. Components: H2 matching one of `Components`, `Widget catalog`.
/// 8. Widgetbook: H2 `## Widgetbook`.
/// 9. Acceptance criteria: H2 matching `Acceptance criteria` (any case,
///    with or without `(Given–When–Then)` subtitle).
///
/// Classification:
///   - **Class A — Full rewrite candidate:** <=4/9 sections present, OR
///     header block absent AND <=6/9 of the remaining sections present.
///   - **Class B — Minor additions:** 5–8/9 sections present AND
///     (header absent OR Behavior incomplete).
///   - **Class C — Compliant:** All 9 sections present, including a
///     complete Behavior section.
///
/// Default scope is the 20 `active`-status registry entries enumerated
/// in issue #2784 (registered against `SPEC/ui/screen-registry.md`).
/// Pass paths as arguments to score a specific subset, or `--all` to
/// score every top-level `SPEC/ui/*.md` file.
///
/// Exit code is `0` when every scored file is Class C, otherwise `1`.
/// `--no-fail` always returns 0 (useful when capturing baselines).

/// 20 `active` registry entries in scope for issue #2784 (path order
/// from `SPEC/ui/screen-registry.md` at the time the issue was filed).
const List<String> _inScopeFiles = <String>[
  'SPEC/ui/shell-screen.md',
  'SPEC/ui/main-menu.md',
  'SPEC/ui/game-setup.md',
  'SPEC/ui/game-screen.md',
  'SPEC/ui/production-panel.md',
  'SPEC/ui/diplomacy-panel.md',
  'SPEC/ui/technology-panel.md',
  'SPEC/ui/empire-overview.md',
  'SPEC/ui/province-sea-zone-detail-overlay.md',
  'SPEC/ui/civilian-units-panel.md',
  'SPEC/ui/military-units-panel.md',
  'SPEC/ui/naval-units-panel.md',
  'SPEC/ui/new-game-leader-selection-dialog.md',
  'SPEC/ui/move-army-dialog.md',
  'SPEC/ui/move-fleet-dialog.md',
  'SPEC/ui/transfer-to-home-fleet-dialog.md',
  'SPEC/ui/game-start-intro-overlay.md',
  'SPEC/ui/victory-overlay.md',
  'SPEC/ui/overture-dialogue-overlay.md',
  'SPEC/ui/quick-battle-screen.md',
];

/// Result of scoring one spec file.
class ScreenSpecScore {
  ScreenSpecScore({
    required this.path,
    required this.headerBlock,
    required this.widgetContract,
    required this.triggerConditions,
    required this.layoutWireframe,
    required this.behavior,
    required this.behaviorComplete,
    required this.statesAndVariants,
    required this.components,
    required this.widgetbook,
    required this.acceptanceCriteria,
  });

  final String path;
  final bool headerBlock;
  final bool widgetContract;
  final bool triggerConditions;
  final bool layoutWireframe;
  final bool behavior;
  final bool behaviorComplete;
  final bool statesAndVariants;
  final bool components;
  final bool widgetbook;
  final bool acceptanceCriteria;

  /// Count of present sections, where Behavior counts iff
  /// [behaviorComplete] (the rubric's stricter Behavior gate).
  int get sectionsPresent {
    var n = 0;
    if (headerBlock) n++;
    if (widgetContract) n++;
    if (triggerConditions) n++;
    if (layoutWireframe) n++;
    if (behaviorComplete) n++;
    if (statesAndVariants) n++;
    if (components) n++;
    if (widgetbook) n++;
    if (acceptanceCriteria) n++;
    return n;
  }

  /// Sections present excluding the header block (used by the Class A
  /// "header absent and <=6/9 other sections" branch).
  int get nonHeaderSectionsPresent {
    var n = 0;
    if (widgetContract) n++;
    if (triggerConditions) n++;
    if (layoutWireframe) n++;
    if (behaviorComplete) n++;
    if (statesAndVariants) n++;
    if (components) n++;
    if (widgetbook) n++;
    if (acceptanceCriteria) n++;
    return n;
  }

  String get classification {
    final present = sectionsPresent;
    final nonHeader = nonHeaderSectionsPresent;
    final headerMissing = !headerBlock;
    if (present <= 4) return 'A';
    if (headerMissing && nonHeader <= 6) return 'A';
    if (present == 9 && behaviorComplete) return 'C';
    return 'B';
  }

  List<String> get missingSummary {
    final missing = <String>[];
    if (!headerBlock) missing.add('Header');
    if (!widgetContract) missing.add('WidgetContract');
    if (!triggerConditions) missing.add('Triggers');
    if (!layoutWireframe) missing.add('Layout');
    if (!behavior) {
      missing.add('Behavior');
    } else if (!behaviorComplete) {
      missing.add('Behavior(subs)');
    }
    if (!statesAndVariants) missing.add('States');
    if (!components) missing.add('Components');
    if (!widgetbook) missing.add('Widgetbook');
    if (!acceptanceCriteria) missing.add('AC');
    return missing;
  }
}

/// Heading text patterns (lower-cased, after stripping `## ` / `### `).
const List<String> _triggerHeadings = <String>[
  'trigger conditions',
  'triggers',
  'trigger',
  'access',
  'panel placement and opening',
];
const List<String> _layoutHeadings = <String>[
  'layout / wireframe',
  'layout',
  'wireframe',
  'wireframe (conceptual)',
];
const List<String> _behaviorHeadings = <String>[
  'behavior',
  'behaviour',
  'actions',
  'user actions',
];
const List<String> _statesHeadings = <String>[
  'states and variants',
  'states',
  'variants',
];
const List<String> _componentsHeadings = <String>[
  'components',
  'widget catalog',
];

/// Scores one markdown spec file against the rubric.
ScreenSpecScore scoreSpecFile(String relativePath, String contents) {
  final lines = contents.split('\n');
  final h2Headings = <String>[];
  final h3Headings = <String>[];
  var h1Seen = false;
  var headerCandidateBlock = StringBuffer();
  var headerCandidateActive = false;
  var headerCandidateClosed = false;
  for (final raw in lines) {
    final line = raw.trimRight();
    if (!h1Seen) {
      if (line.startsWith('# ')) {
        h1Seen = true;
        headerCandidateActive = true;
      }
      continue;
    }
    if (headerCandidateActive && !headerCandidateClosed) {
      if (line.startsWith('## ')) {
        headerCandidateClosed = true;
      } else if (line.startsWith('---')) {
        headerCandidateClosed = true;
      } else {
        headerCandidateBlock.writeln(line);
      }
    }
    if (line.startsWith('## ')) {
      h2Headings.add(line.substring(3).trim().toLowerCase());
    } else if (line.startsWith('### ')) {
      h3Headings.add(line.substring(4).trim().toLowerCase());
    }
  }

  final headerText = headerCandidateBlock.toString();
  final hasScreenId = headerText.contains('**Screen ID:**');
  final hasSpecUi = headerText.contains('**SPEC/ui**');
  final hasWidgetbookLine = headerText.contains('**Widgetbook:**');
  final headerBlock = hasScreenId && hasSpecUi && hasWidgetbookLine;

  bool hasH2(List<String> options) {
    for (final h in h2Headings) {
      for (final opt in options) {
        if (h == opt || h.startsWith('$opt ') || h.startsWith('$opt:')) {
          return true;
        }
      }
    }
    return false;
  }

  bool hasH3Sub(String label) {
    final target = label.toLowerCase();
    for (final h in h3Headings) {
      if (h == target || h.startsWith('$target ') || h.startsWith('$target:')) {
        return true;
      }
    }
    return false;
  }

  final widgetContract = h2Headings.any((h) => h == 'widget contract');
  final triggerConditions = hasH2(_triggerHeadings);
  final layoutWireframe = hasH2(_layoutHeadings);
  final behavior = hasH2(_behaviorHeadings);
  final behaviorIncoming = hasH3Sub('incoming');
  final behaviorUserActions =
      hasH3Sub('user actions → outcomes') ||
      hasH3Sub('user actions -> outcomes') ||
      hasH3Sub('user actions and outcomes');
  final behaviorComplete = behavior && behaviorIncoming && behaviorUserActions;
  final statesAndVariants = hasH2(_statesHeadings);
  final components = hasH2(_componentsHeadings);
  final widgetbook = h2Headings.any((h) => h == 'widgetbook');
  final acceptanceCriteria = h2Headings.any((h) {
    return h == 'acceptance criteria' ||
        h.startsWith('acceptance criteria (') ||
        h == 'acceptance criteria (given-when-then)' ||
        h == 'acceptance criteria (given–when–then)';
  });

  return ScreenSpecScore(
    path: relativePath,
    headerBlock: headerBlock,
    widgetContract: widgetContract,
    triggerConditions: triggerConditions,
    layoutWireframe: layoutWireframe,
    behavior: behavior,
    behaviorComplete: behaviorComplete,
    statesAndVariants: statesAndVariants,
    components: components,
    widgetbook: widgetbook,
    acceptanceCriteria: acceptanceCriteria,
  );
}

List<String> _expandPaths(List<String> args, {required bool all}) {
  if (all) {
    final dir = Directory('SPEC/ui');
    if (!dir.existsSync()) return const <String>[];
    final files =
        dir
            .listSync()
            .whereType<File>()
            .map((f) => f.path.replaceAll('\\', '/'))
            .where((p) => p.endsWith('.md'))
            .toList()
          ..sort();
    return files;
  }
  if (args.isNotEmpty) return args;
  return _inScopeFiles;
}

int main(List<String> argv) {
  var all = false;
  var noFail = false;
  final paths = <String>[];
  for (final a in argv) {
    if (a == '--all') {
      all = true;
    } else if (a == '--no-fail') {
      noFail = true;
    } else if (a == '--help' || a == '-h') {
      stdout.writeln(
        'Usage: dart run tool/check_ui_spec_template_compliance.dart '
        '[paths...|--all] [--no-fail]',
      );
      return 0;
    } else {
      paths.add(a);
    }
  }
  final targets = _expandPaths(paths, all: all);
  if (targets.isEmpty) {
    stderr.writeln('No files to score.');
    return noFail ? 0 : 1;
  }
  final scores = <ScreenSpecScore>[];
  for (final relative in targets) {
    final file = File(relative);
    if (!file.existsSync()) {
      stderr.writeln('check_ui_spec_template_compliance: missing $relative');
      scores.add(
        ScreenSpecScore(
          path: relative,
          headerBlock: false,
          widgetContract: false,
          triggerConditions: false,
          layoutWireframe: false,
          behavior: false,
          behaviorComplete: false,
          statesAndVariants: false,
          components: false,
          widgetbook: false,
          acceptanceCriteria: false,
        ),
      );
      continue;
    }
    final contents = file.readAsStringSync();
    scores.add(scoreSpecFile(relative, contents));
  }

  // Markdown-friendly aligned table.
  stdout.writeln('| File | Score | Class | Missing |');
  stdout.writeln('|------|-------|-------|---------|');
  var nonCompliant = 0;
  for (final s in scores) {
    final missing = s.missingSummary.isEmpty
        ? '—'
        : s.missingSummary.join(', ');
    stdout.writeln(
      '| ${s.path} | ${s.sectionsPresent}/9 | ${s.classification} | $missing |',
    );
    if (s.classification != 'C') nonCompliant++;
  }

  final classCounts = <String, int>{'A': 0, 'B': 0, 'C': 0};
  for (final s in scores) {
    classCounts[s.classification] = (classCounts[s.classification] ?? 0) + 1;
  }
  stdout.writeln('');
  stdout.writeln(
    'Totals: ${scores.length} files | '
    'A=${classCounts['A']}, B=${classCounts['B']}, C=${classCounts['C']}',
  );

  if (nonCompliant == 0) {
    return 0;
  }
  return noFail ? 0 : 1;
}
