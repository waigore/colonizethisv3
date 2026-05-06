import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/no_generic_domain_throw_rule.dart';
import 'src/no_raw_home_fleet_id_rule.dart';

PluginBase createPlugin() => _ColonizeThisExceptionLint();

class _ColonizeThisExceptionLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    NoGenericDomainThrowRule(),
    NoRawHomeFleetIdRule(),
  ];
}
