import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// PR-blocking structural gate that statically enforces the collapsed
/// single-step blocking-dialogue contract (Refs #3628) so a new Jenny overlay
/// cannot regress the presentation by bypassing [_ctBody] or omitting
/// combined-step golden coverage.
///
/// The four blocking Jenny overlays (`GameStartIntroOverlay`,
/// `TribeFirstContactOverlay`, `OvertureDialogueOverlay`,
/// `InterventionDialogueOverlay`) each construct a `CtDialogueView` and delegate
/// line/choice rendering to the shared `CtDialogueLineChoiceBody`, which is the
/// only widget allowed to wire `advanceLine` / `selectOption` /
/// `confirmCombinedLineOption` on the view. The combined-step goldens in
/// [_goldenTestRelative] must cover every overlay that constructs a view.
///
/// Three checks run over `app/lib/features/game/dialogue/**/*.dart`:
///
/// 1. **Adoption** — any file that constructs `CtDialogueView(` must also
///    construct `CtDialogueLineChoiceBody(` (canonical and exempt files
///    skipped).
/// 2. **No bespoke wiring** — overlay files must not invoke or tear off
///    `advanceLine` / `selectOption` / `confirmCombinedLineOption` on a view
///    receiver; only `ct_dialogue_line_choice_body.dart` may.
/// 3. **Golden registry parity** — the set of `*_overlay.dart` files that
///    construct `CtDialogueView(` must equal the set of dialogue overlays
///    imported by [_goldenTestRelative] (symmetric-difference fail).
///
/// SPEC: `SPEC/ui/ct-dialogue-view.md`; `SPEC/program/repo-lint.md`.
const String _dialogueDirRelative = 'app/lib/features/game/dialogue';
const String _goldenTestRelative =
    'app/test/dialogue_combined_line_choice_goldens_test.dart';

const String _ctView = 'CtDialogueView';
const String _ctBody = 'CtDialogueLineChoiceBody';

/// Canonical files that declare the dialogue contract itself (they define, not
/// consume, the view/body and so are exempt from adoption and wiring checks).
const Set<String> _canonicalBasenames = <String>{
  'ct_dialogue_view.dart',
  'ct_dialogue_line_choice_body.dart',
};

/// Blocking diplomacy overlay that intentionally does not use `CtDialogueView`
/// (no Jenny line/choice flow). Exempt from adoption and wiring checks; it never
/// enters the golden registry set because it does not construct a view.
const String _exemptOverlayBasename = 'call_to_arms_dialogue_overlay.dart';

/// View methods that drive line/choice progression. Only the canonical body may
/// invoke these on the view; overlays must delegate.
const Set<String> _forbiddenViewMethods = <String>{
  'advanceLine',
  'selectOption',
  'confirmCombinedLineOption',
};

/// Import suffix that identifies a dialogue overlay import in the golden test.
final RegExp _goldenOverlayImportPattern = RegExp(
  r'''['"][^'"]*features/game/dialogue/([A-Za-z0-9_]+_overlay\.dart)['"]''',
);

/// Used by `ct_repo_lint` / `dart run`; [info] / [err] default to std streams.
int runCheckDialogueBlockingCombinedStep(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final dialogueDir = Directory(p.join(root, _dialogueDirRelative));
  if (!dialogueDir.existsSync()) {
    logE('check_dialogue_blocking_combined_step: missing $_dialogueDirRelative');
    return 1;
  }
  final goldenTest = File(p.join(root, _goldenTestRelative));
  if (!goldenTest.existsSync()) {
    logE('check_dialogue_blocking_combined_step: missing $_goldenTestRelative');
    return 1;
  }

  final adoptionViolations = <String>[];
  final wiringViolations = <String>[];
  final ctViewOverlays = <String>{};

  final files =
      dialogueDir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final relPath = p
        .relative(file.path, from: root)
        .replaceAll('\\', '/');
    final basename = p.basename(file.path);
    final analysis = _analyzeDialogueFile(
      file.readAsStringSync(),
      relPath,
    );

    final isCanonical = _canonicalBasenames.contains(basename);
    final isExemptOverlay = basename == _exemptOverlayBasename;

    // Check 3 input: structural set of view-constructing overlay basenames.
    if (basename.endsWith('_overlay.dart') && analysis.constructsCtView) {
      ctViewOverlays.add(basename);
    }

    if (isCanonical || isExemptOverlay) {
      continue;
    }

    // Check 1: adoption.
    if (analysis.constructsCtView && !analysis.constructsCtBody) {
      adoptionViolations.add(
        '$relPath: constructs $_ctView( but never constructs $_ctBody( — '
        'delegate Yarn line/choice rendering to $_ctBody instead of '
        're-implementing line/choice branches (Refs #3628).',
      );
    }

    // Check 2: no bespoke wiring.
    for (final ref in analysis.forbiddenViewRefs) {
      wiringViolations.add(
        '$relPath:${ref.line}: overlay invokes `${ref.method}` on the view — '
        'only ct_dialogue_line_choice_body.dart may wire $_ctView '
        '${_forbiddenViewMethods.join(' / ')}; delegate to $_ctBody '
        '(Refs #3628).',
      );
    }
  }

  // Check 3: golden registry parity.
  final goldenOverlays = _goldenOverlayBasenames(goldenTest.readAsStringSync());
  final missingGolden = ctViewOverlays.difference(goldenOverlays).toList()
    ..sort();
  final staleGolden = goldenOverlays.difference(ctViewOverlays).toList()..sort();
  final registryViolations = <String>[];
  for (final basename in missingGolden) {
    registryViolations.add(
      '$basename constructs $_ctView( but is not imported by '
      '$_goldenTestRelative — add a combined-step golden test for it '
      '(Refs #3628).',
    );
  }
  for (final basename in staleGolden) {
    registryViolations.add(
      '$_goldenTestRelative imports $basename but no such overlay constructs '
      '$_ctView( under $_dialogueDirRelative — remove the stale golden import '
      '(Refs #3628).',
    );
  }

  final hasViolations =
      adoptionViolations.isNotEmpty ||
      wiringViolations.isNotEmpty ||
      registryViolations.isNotEmpty;
  if (!hasViolations) {
    logI(
      'check_dialogue_blocking_combined_step: blocking dialogue overlays adopt '
      '$_ctBody and combined-step goldens are in parity.',
    );
    return 0;
  }

  logE(
    'ERROR: blocking Jenny dialogue overlays must use $_ctBody and register '
    'combined-step goldens (Refs #3628).',
  );
  for (final v in adoptionViolations) {
    logE(' - [adoption] $v');
  }
  for (final v in wiringViolations) {
    logE(' - [wiring] $v');
  }
  for (final v in registryViolations) {
    logE(' - [golden-registry] $v');
  }
  return 1;
}

/// Parsed dialogue-file facts used by the three checks.
class _DialogueFileAnalysis {
  _DialogueFileAnalysis({
    required this.constructsCtView,
    required this.constructsCtBody,
    required this.forbiddenViewRefs,
  });

  final bool constructsCtView;
  final bool constructsCtBody;
  final List<({String method, int line})> forbiddenViewRefs;
}

_DialogueFileAnalysis _analyzeDialogueFile(String source, String relPath) {
  final parsed = parseString(
    content: source,
    path: relPath,
    throwIfDiagnostics: false,
  );
  final visitor = _DialogueFileVisitor(parsed.unit.lineInfo);
  parsed.unit.accept(visitor);
  return _DialogueFileAnalysis(
    constructsCtView: visitor.constructsCtView,
    constructsCtBody: visitor.constructsCtBody,
    forbiddenViewRefs: visitor.forbiddenViewRefs,
  );
}

class _DialogueFileVisitor extends RecursiveAstVisitor<void> {
  _DialogueFileVisitor(this.lineInfo);

  final LineInfo lineInfo;
  bool constructsCtView = false;
  bool constructsCtBody = false;
  final List<({String method, int line})> forbiddenViewRefs = [];

  void _recordConstruction(String typeName) {
    if (typeName == _ctView) constructsCtView = true;
    if (typeName == _ctBody) constructsCtBody = true;
  }

  void _recordForbidden(String name, int offset) {
    if (!_forbiddenViewMethods.contains(name)) return;
    forbiddenViewRefs.add((
      method: name,
      line: lineInfo.getLocation(offset).lineNumber,
    ));
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _recordConstruction(node.constructorName.type.name.lexeme);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (node.target == null && node.realTarget == null) {
      // Unresolved constructor-call form `CtDialogueView(...)` (the analyzer
      // only rewrites these to InstanceCreationExpression during resolution).
      _recordConstruction(name);
    } else {
      _recordForbidden(name, node.methodName.offset);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Tear-off form `view.advanceLine` (no call parentheses).
    _recordForbidden(node.identifier.name, node.identifier.offset);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // Null-aware / chained tear-off form `view?.advanceLine`.
    _recordForbidden(node.propertyName.name, node.propertyName.offset);
    super.visitPropertyAccess(node);
  }
}

/// Basenames of dialogue overlay files imported by the golden test.
Set<String> _goldenOverlayBasenames(String goldenSource) {
  final result = <String>{};
  for (final match in _goldenOverlayImportPattern.allMatches(goldenSource)) {
    result.add(match.group(1)!);
  }
  return result;
}

void main() {
  exit(runCheckDialogueBlockingCombinedStep(Directory.current.path));
}
