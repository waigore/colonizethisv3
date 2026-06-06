import 'package:yaml/yaml.dart';

/// Kinds of structural matches defined in [tool/disallowed_ast_patterns.yaml].
enum DisallowedAstMatchKind {
  cascadedMethodInvocation,
  streamWhereIsMapAs,
  commentSubstring,
  rawNamedType,
  methodBodyLineSpan,
  seaZoneLocalIdExtraction,
  seaZoneBucketLookupWithoutCanonicalKey,
  unprefixedProvinceIdStringLiteralArgument,
  provinceLocalSegmentBoundaryOnly,
  scopedPackageImportContract,
  simpleReceiverRemoveAtZero,
  linearCollectionWhereFirstOrNull,
  incrementalValidatorForPlayerInLoop,
  redundantWhereToListWhereChain,
  nestedWorldStateCopyWith,
  staticMemberAccess,
}

class DisallowedPatternRule {
  const DisallowedPatternRule({
    required this.id,
    required this.message,
    required this.kind,
    required this.cascadedMethodNames,
    required this.commentSubstring,
    required this.rawNamedTypeNames,
    required this.functionName,
    required this.maxBodyLineSpan,
    required this.requireWidgetClassExtends,
    required this.argumentIndex,
    required this.invocationMethodNames,
    required this.allowedRelativePaths,
    required this.scopedRelativePathPrefixes,
    required this.packageName,
    required this.allowedPackageImports,
    this.removeAtZeroReceiverPathPrefix,
    this.removeAtZeroReceiverIdentifier,
    this.linearCollectionNames = const {},
    this.linearCollectionPathPrefix,
    this.nestedCopyWithOuterArgumentName,
    this.staticMemberTypeName,
    this.staticMemberName,
    this.staticMemberPathPrefix,
  });

  final String id;
  final String message;
  final DisallowedAstMatchKind kind;
  final Set<String> cascadedMethodNames;
  final String? commentSubstring;
  final Set<String> rawNamedTypeNames;
  final String? functionName;
  final int? maxBodyLineSpan;
  final bool requireWidgetClassExtends;
  final int? argumentIndex;
  final Set<String> invocationMethodNames;
  final Set<String> allowedRelativePaths;
  final Set<String> scopedRelativePathPrefixes;
  final String? packageName;
  final Set<String> allowedPackageImports;

  /// When [kind] is [DisallowedAstMatchKind.simpleReceiverRemoveAtZero]: relative
  /// path prefix (POSIX slashes) limiting matches, e.g. `packages/colonizethis_logic/lib/src/`.
  final String? removeAtZeroReceiverPathPrefix;

  /// When [kind] is [DisallowedAstMatchKind.simpleReceiverRemoveAtZero]: simple
  /// identifier of the receiver for `removeAt(0)` (typically `queue`).
  final String? removeAtZeroReceiverIdentifier;

  /// When [kind] is [DisallowedAstMatchKind.linearCollectionWhereFirstOrNull]:
  /// names of getters/no-arg methods whose `.where(...).firstOrNull` chains
  /// are linear-scan anti-patterns (for example `provinces`).
  final Set<String> linearCollectionNames;

  /// When [kind] is [DisallowedAstMatchKind.linearCollectionWhereFirstOrNull]
  /// or other path-scoped rules (e.g. [DisallowedAstMatchKind.nestedWorldStateCopyWith]):
  /// path prefix (POSIX slashes) limiting matches, for example
  /// `packages/colonizethis_logic/lib/src/`.
  final String? linearCollectionPathPrefix;

  /// When [kind] is [DisallowedAstMatchKind.nestedWorldStateCopyWith]: the
  /// outer `copyWith(<arg>:`) named-argument label that anchors the chain
  /// (defaults to `worldState`). Only chains whose outermost `copyWith` passes
  /// that named argument are scanned for deeper nesting.
  final String? nestedCopyWithOuterArgumentName;

  /// When [kind] is [DisallowedAstMatchKind.staticMemberAccess]: the simple
  /// type-name prefix of the disallowed static access (for example
  /// `ProductionRecipesCatalog` in `ProductionRecipesCatalog.all`).
  final String? staticMemberTypeName;

  /// When [kind] is [DisallowedAstMatchKind.staticMemberAccess]: the accessed
  /// member name (for example `all`).
  final String? staticMemberName;

  /// When [kind] is [DisallowedAstMatchKind.staticMemberAccess]: path prefix
  /// (POSIX slashes) limiting matches, for example
  /// `packages/colonizethis_ai/lib/`.
  final String? staticMemberPathPrefix;
}

class DisallowedAstViolation {
  const DisallowedAstViolation({
    required this.path,
    required this.line,
    required this.ruleId,
    required this.message,
  });

  final String path;
  final int line;
  final String ruleId;
  final String message;
}

/// Parses the `rules` list from a loaded YAML root (same contract as production).
List<DisallowedPatternRule> parseDisallowedAstRulesFromYaml(Object? yamlRoot) {
  if (yamlRoot is! YamlMap) {
    return const [];
  }
  final rulesNode = yamlRoot['rules'];
  if (rulesNode is! YamlList) {
    return const [];
  }
  final out = <DisallowedPatternRule>[];
  for (final entry in rulesNode.nodes) {
    final value = entry.value;
    if (value is! YamlMap) {
      continue;
    }
    final id = value['id']?.toString();
    final message = value['message']?.toString().trim();
    final match = value['match'];
    if (id == null || id.isEmpty || message == null || message.isEmpty) {
      continue;
    }
    if (match is! YamlMap) {
      continue;
    }
    final kind = match['kind']?.toString();
    if (kind == 'cascaded_method_invocation') {
      final namesNode = match['method_names'];
      if (namesNode is! YamlList) {
        continue;
      }
      final names = <String>{};
      for (final n in namesNode.nodes) {
        final s = n.value?.toString();
        if (s != null && s.isNotEmpty) {
          names.add(s);
        }
      }
      if (names.isEmpty) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.cascadedMethodInvocation,
          cascadedMethodNames: names,
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'stream_where_is_map_as') {
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.streamWhereIsMapAs,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'comment_substring') {
      final needle = match['contains']?.toString();
      if (needle == null || needle.isEmpty) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.commentSubstring,
          cascadedMethodNames: const {},
          commentSubstring: needle,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'raw_named_type') {
      final namesNode = match['type_names'];
      if (namesNode is! YamlList) {
        continue;
      }
      final names = <String>{};
      for (final n in namesNode.nodes) {
        final s = n.value?.toString();
        if (s != null && s.isNotEmpty) {
          names.add(s);
        }
      }
      if (names.isEmpty) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.rawNamedType,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: names,
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'method_body_line_span') {
      final functionName = match['function_name']?.toString();
      final maxBodyLineSpan = int.tryParse(
        match['max_body_line_span']?.toString() ?? '',
      );
      final requireWidgetClassExtends =
          match['require_widget_class_extends'] == true;
      if (functionName == null ||
          functionName.isEmpty ||
          maxBodyLineSpan == null ||
          maxBodyLineSpan < 1) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.methodBodyLineSpan,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: functionName,
          maxBodyLineSpan: maxBodyLineSpan,
          requireWidgetClassExtends: requireWidgetClassExtends,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'unprefixed_province_id_string_literal_argument') {
      final namesNode = match['method_names'];
      final argumentIndex = int.tryParse(
        match['argument_index']?.toString() ?? '',
      );
      if (namesNode is! YamlList ||
          argumentIndex == null ||
          argumentIndex < 0) {
        continue;
      }
      final names = <String>{};
      for (final n in namesNode.nodes) {
        final s = n.value?.toString();
        if (s != null && s.isNotEmpty) {
          names.add(s);
        }
      }
      if (names.isEmpty) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind:
              DisallowedAstMatchKind.unprefixedProvinceIdStringLiteralArgument,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: argumentIndex,
          invocationMethodNames: names,
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'sea_zone_local_id_extraction') {
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.seaZoneLocalIdExtraction,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'sea_zone_bucket_lookup_without_canonical_key') {
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.seaZoneBucketLookupWithoutCanonicalKey,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'province_local_segment_boundary_only') {
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.provinceLocalSegmentBoundaryOnly,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'simple_receiver_remove_at_zero') {
      final prefix =
          match['relative_path_prefix']?.toString().replaceAll('\\', '/');
      final receiver = match['receiver_identifier']?.toString();
      if (prefix == null ||
          prefix.isEmpty ||
          receiver == null ||
          receiver.isEmpty) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.simpleReceiverRemoveAtZero,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
          removeAtZeroReceiverPathPrefix: prefix,
          removeAtZeroReceiverIdentifier: receiver,
        ),
      );
    } else if (kind == 'linear_collection_where_first_or_null') {
      final namesNode = match['collection_names'];
      final prefix =
          match['relative_path_prefix']?.toString().replaceAll('\\', '/');
      if (namesNode is! YamlList ||
          prefix == null ||
          prefix.isEmpty) {
        continue;
      }
      final names = <String>{};
      for (final n in namesNode.nodes) {
        final s = n.value?.toString();
        if (s != null && s.isNotEmpty) {
          names.add(s);
        }
      }
      if (names.isEmpty) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.linearCollectionWhereFirstOrNull,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
          linearCollectionNames: names,
          linearCollectionPathPrefix: prefix,
        ),
      );
    } else if (kind == 'redundant_where_to_list_where_chain') {
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.redundantWhereToListWhereChain,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
        ),
      );
    } else if (kind == 'incremental_validator_for_player_in_loop') {
      final prefix =
          match['relative_path_prefix']?.toString().replaceAll('\\', '/');
      if (prefix == null || prefix.isEmpty) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.incrementalValidatorForPlayerInLoop,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
          linearCollectionPathPrefix: prefix,
        ),
      );
    } else if (kind == 'nested_world_state_copywith') {
      final prefix =
          match['relative_path_prefix']?.toString().replaceAll('\\', '/');
      if (prefix == null || prefix.isEmpty) {
        continue;
      }
      final outerArgumentName = match['outer_argument_name']?.toString();
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.nestedWorldStateCopyWith,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
          linearCollectionPathPrefix: prefix,
          nestedCopyWithOuterArgumentName:
              outerArgumentName != null && outerArgumentName.isNotEmpty
                  ? outerArgumentName
                  : 'worldState',
        ),
      );
    } else if (kind == 'static_member_access') {
      final typeName = match['type_name']?.toString();
      final memberName = match['member_name']?.toString();
      final prefix =
          match['relative_path_prefix']?.toString().replaceAll('\\', '/');
      if (typeName == null ||
          typeName.isEmpty ||
          memberName == null ||
          memberName.isEmpty ||
          prefix == null ||
          prefix.isEmpty) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.staticMemberAccess,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: const {},
          packageName: null,
          allowedPackageImports: const {},
          staticMemberTypeName: typeName,
          staticMemberName: memberName,
          staticMemberPathPrefix: prefix,
        ),
      );
    } else if (kind == 'scoped_package_import_contract') {
      final scopeNode = match['scoped_relative_path_prefixes'];
      final packageName = match['package_name']?.toString();
      final allowedImportsYamlList = match['allowed_imports'];
      if (scopeNode is! YamlList ||
          packageName == null ||
          packageName.isEmpty ||
          allowedImportsYamlList is! YamlList) {
        continue;
      }
      final scopedRelativePathPrefixes = <String>{};
      for (final scopeEntry in scopeNode.nodes) {
        final scope = scopeEntry.value?.toString();
        if (scope != null && scope.isNotEmpty) {
          scopedRelativePathPrefixes.add(scope);
        }
      }
      final allowedPackageImports = <String>{};
      for (final importUriEntry in allowedImportsYamlList.nodes) {
        final importPath = importUriEntry.value?.toString();
        if (importPath != null && importPath.isNotEmpty) {
          allowedPackageImports.add(importPath);
        }
      }
      if (scopedRelativePathPrefixes.isEmpty || allowedPackageImports.isEmpty) {
        continue;
      }
      out.add(
        DisallowedPatternRule(
          id: id,
          message: message,
          kind: DisallowedAstMatchKind.scopedPackageImportContract,
          cascadedMethodNames: const {},
          commentSubstring: null,
          rawNamedTypeNames: const {},
          functionName: null,
          maxBodyLineSpan: null,
          requireWidgetClassExtends: false,
          argumentIndex: null,
          invocationMethodNames: const {},
          allowedRelativePaths: const {},
          scopedRelativePathPrefixes: scopedRelativePathPrefixes,
          packageName: packageName,
          allowedPackageImports: allowedPackageImports,
        ),
      );
    }
  }
  return out;
}
