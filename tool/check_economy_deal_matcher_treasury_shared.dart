import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3856 / #3979).
///
/// Guards shared deal-matcher treasury affordability helpers in
/// `treasury_bid_budget.dart`. After de-part, match attempts live in
/// `deal_matcher_session.dart` and must call the shared symbols;
/// `deal_matcher_indexing.dart` must not redefine local treasury math.
const _helperRelativePath =
    'packages/colonizethis_economy/lib/src/economy/world_market/treasury_bid_budget.dart';

const _consumerRelativePath =
    'packages/colonizethis_economy/lib/src/economy/world_market/deal_matcher_indexing.dart';

const _sessionRelativePath =
    'packages/colonizethis_economy/lib/src/economy/world_market/deal_matcher_session.dart';

const _sharedMaxAffordableSymbol = 'maxAffordableBidQuantity';
const _sharedDecrementSymbol = 'decrementTreasuryForFill';

final RegExp _forbiddenPrivateMaxAffordable = RegExp(
  r'int\s+_maxAffordableQuantity\s*\(',
);
final RegExp _forbiddenPrivateDecrement = RegExp(
  r'void\s+_decrementTreasury\s*\(',
);

const _economyLibPrefix = 'packages/colonizethis_economy/lib/';

void main() {
  exit(runCheckEconomyDealMatcherTreasuryShared(Directory.current.path));
}

int runCheckEconomyDealMatcherTreasuryShared(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final helperFile = File(p.join(root, _helperRelativePath));
  if (!helperFile.existsSync()) {
    logE(
      'ERROR: Missing shared treasury budget helper file: '
      '$_helperRelativePath',
    );
    return 1;
  }
  final helperSource = helperFile.readAsStringSync();
  for (final symbol in [_sharedMaxAffordableSymbol, _sharedDecrementSymbol]) {
    if (!helperSource.contains('$symbol(')) {
      logE(
        'ERROR: $_helperRelativePath no longer defines `$symbol`; '
        'deal-matcher treasury math must stay centralized (Refs #3856).',
      );
      return 1;
    }
  }

  final sessionFile = File(p.join(root, _sessionRelativePath));
  if (!sessionFile.existsSync()) {
    logE('ERROR: Missing deal matcher session: $_sessionRelativePath');
    return 1;
  }
  final sessionSource = sessionFile.readAsStringSync();
  for (final symbol in [_sharedMaxAffordableSymbol, _sharedDecrementSymbol]) {
    if (!sessionSource.contains('$symbol(')) {
      logE(
        'ERROR: $_sessionRelativePath must call `$symbol` from '
        'treasury_bid_budget.dart (Refs #3856).',
      );
      return 1;
    }
  }

  final consumerFile = File(p.join(root, _consumerRelativePath));
  if (!consumerFile.existsSync()) {
    logE('ERROR: Missing deal matcher indexing: $_consumerRelativePath');
    return 1;
  }
  final consumerSource = consumerFile.readAsStringSync();
  if (_forbiddenPrivateMaxAffordable.hasMatch(consumerSource) ||
      _forbiddenPrivateDecrement.hasMatch(consumerSource)) {
    logE(
      'ERROR: $_consumerRelativePath must not define private treasury '
      'helpers; delegate to treasury_bid_budget.dart (Refs #3856).',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: root).replaceAll('\\', '/');
    if (!rel.startsWith(_economyLibPrefix) || rel == _helperRelativePath) {
      continue;
    }
    final source = file.readAsStringSync();
    if (_forbiddenPrivateMaxAffordable.hasMatch(source) ||
        _forbiddenPrivateDecrement.hasMatch(source)) {
      violations.add(
        '$rel: private deal-matcher treasury helpers must delegate to '
        'treasury_bid_budget.dart (Refs #3856)',
      );
    }
  }

  if (violations.isNotEmpty) {
    logE(
      'check_economy_deal_matcher_treasury_shared: ${violations.length} '
      'violation(s):',
    );
    for (final violation in violations) {
      logE(' - $violation');
    }
    return 1;
  }

  logI('Economy deal-matcher treasury shared-helper check passed.');
  return 0;
}
