import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Shared H8 flagged-seller Game scaffold (Refs #4084).
const String aiContractsH8FlaggedSellerSupportFile =
    'packages/colonizethis_ai_contracts/test/support/h8_flagged_seller_game.dart';

/// Shared H8 supplier prospect Game scaffold (Refs #4084).
const String aiContractsH8SupplierProspectSupportFile =
    'packages/colonizethis_ai_contracts/test/support/h8_supplier_prospect_game.dart';

/// Seller acquisition-target pins that must use [flaggedSellerGame].
const Set<String> aiContractsH8FlaggedSellerAdopters = <String>{
  'packages/colonizethis_ai_contracts/test/'
      'full_ai_civilian_work_seller_feedstock_acquisition_target_test.dart',
  'packages/colonizethis_ai_contracts/test/'
      'full_ai_civilian_work_seller_feedstock_acquisition_target_pick_test.dart',
  'packages/colonizethis_ai_contracts/test/'
      'full_ai_civilian_work_seller_feedstock_acquisition_target_among_acquirable_test.dart',
};

/// OW prospect pins that must use [supplierGame].
const Set<String> aiContractsH8SupplierProspectAdopters = <String>{
  'packages/colonizethis_ai_contracts/test/'
      'full_ai_civilian_work_ow_feedstock_prospect_localization_test.dart',
  'packages/colonizethis_ai_contracts/test/'
      'full_ai_civilian_work_ow_feedstock_prospect_mineral_eligibility_test.dart',
};

final RegExp _localFlaggedSellerGameDecl = RegExp(
  r'Game\s+_flaggedSellerGame\b',
);

final RegExp _localSupplierGameDecl = RegExp(r'Game\s+_supplierGame\b');

String _normalizeSlash(String path) => path.replaceAll('\\', '/');

/// True when [slashPath] is a flagged-seller acquisition adopter pin.
bool aiContractsH8FlaggedSellerPathInScope(String slashPath) {
  return aiContractsH8FlaggedSellerAdopters.contains(
    _normalizeSlash(slashPath),
  );
}

/// True when [slashPath] is an OW supplier prospect adopter pin.
bool aiContractsH8SupplierProspectPathInScope(String slashPath) {
  return aiContractsH8SupplierProspectAdopters.contains(
    _normalizeSlash(slashPath),
  );
}

/// Returns a violation reason when an adopter redeclares a local H8 Game clone.
String? aiContractsH8TestSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = _normalizeSlash(slashPath);
  if (aiContractsH8FlaggedSellerPathInScope(normalized) &&
      _localFlaggedSellerGameDecl.hasMatch(content)) {
    return 'redeclares local `_flaggedSellerGame`; import '
        '`flaggedSellerGame` from `$aiContractsH8FlaggedSellerSupportFile` '
        '(Refs #4084)';
  }
  if (aiContractsH8SupplierProspectPathInScope(normalized) &&
      _localSupplierGameDecl.hasMatch(content)) {
    return 'redeclares local `_supplierGame`; import '
        '`supplierGame` from `$aiContractsH8SupplierProspectSupportFile` '
        '(Refs #4084)';
  }
  return null;
}

int runCheckAiContractsH8TestSharedFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final flaggedSellerSupport = p.join(
    repoRoot,
    'packages',
    'colonizethis_ai_contracts',
    'test',
    'support',
    'h8_flagged_seller_game.dart',
  );
  final supplierSupport = p.join(
    repoRoot,
    'packages',
    'colonizethis_ai_contracts',
    'test',
    'support',
    'h8_supplier_prospect_game.dart',
  );
  if (!File(flaggedSellerSupport).existsSync()) {
    logE(
      'check_ai_contracts_h8_test_shared_fixtures: missing shared support '
      'file `$aiContractsH8FlaggedSellerSupportFile`.',
    );
    return 1;
  }
  if (!File(supplierSupport).existsSync()) {
    logE(
      'check_ai_contracts_h8_test_shared_fixtures: missing shared support '
      'file `$aiContractsH8SupplierProspectSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiContractsH8TestSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_contracts_h8_test_shared_fixtures: no local '
      '`_flaggedSellerGame` / `_supplierGame` redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_contracts_h8_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiContractsH8TestSharedFixtures(Directory.current.path));
}
