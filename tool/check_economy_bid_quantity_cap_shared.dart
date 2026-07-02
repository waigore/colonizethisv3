import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3836).
///
/// Guards the shared bid-quantity cap helper in the economy package.
/// `treasury_bid_budget.dart` owns `capBidQuantityForBudgets`; the suggester
/// must delegate to it instead of re-inlining cargo + treasury capping.
const _helperRelativePath =
    'packages/colonizethis_economy/lib/src/economy/world_market/treasury_bid_budget.dart';

const _consumerRelativePath =
    'packages/colonizethis_economy/lib/src/economy/world_market/trade_order_suggester.dart';

const _sharedSymbol = 'capBidQuantityForBudgets';

final RegExp _forbiddenInlineCapPattern = RegExp(
  r'remainingTreasuryBudget\s*~/\s*unitPrice',
);

const _economyLibPrefix = 'packages/colonizethis_economy/lib/';

void main() {
  exit(runCheckEconomyBidQuantityCapShared(Directory.current.path));
}

int runCheckEconomyBidQuantityCapShared(
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
      'ERROR: Missing shared bid-quantity-cap helper file: '
      '$_helperRelativePath',
    );
    return 1;
  }
  final helperSource = helperFile.readAsStringSync();
  if (!helperSource.contains('$_sharedSymbol(')) {
    logE(
      'ERROR: $_helperRelativePath no longer defines `$_sharedSymbol`; '
      'bid quantity cap must stay centralized (Refs #3836).',
    );
    return 1;
  }

  final consumerFile = File(p.join(root, _consumerRelativePath));
  if (!consumerFile.existsSync()) {
    logE('ERROR: Missing bid-cap consumer: $_consumerRelativePath');
    return 1;
  }
  final consumerSource = consumerFile.readAsStringSync();
  if (!consumerSource.contains('$_sharedSymbol(')) {
    logE(
      'ERROR: $_consumerRelativePath must call `$_sharedSymbol` instead of '
      're-inlining bid quantity capping (Refs #3836).',
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
    if (_forbiddenInlineCapPattern.hasMatch(source)) {
      violations.add(
        '$rel: inline `remainingTreasuryBudget ~/ unitPrice` must delegate '
        'to capBidQuantityForBudgets in treasury_bid_budget.dart (Refs #3836)',
      );
    }
  }

  if (violations.isNotEmpty) {
    logE(
      'check_economy_bid_quantity_cap_shared: ${violations.length} '
      'violation(s):',
    );
    for (final violation in violations) {
      logE(' - $violation');
    }
    return 1;
  }

  logI('Economy bid-quantity-cap shared-helper check passed.');
  return 0;
}
