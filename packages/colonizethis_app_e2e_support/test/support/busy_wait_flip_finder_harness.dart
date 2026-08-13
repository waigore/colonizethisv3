// Shared flip-finder spy for `e2e_busy_wait_final_check_test.dart` (#4344
// Slice C densify). The suite previously declared two near-identical
// `Finder` spies (`_FlipFinder` / `_FlipFinder3`) that only differed by how
// many leading `findInCandidates` calls stayed empty before the target
// finder took over. [FlipFinder.succeedOnCall] unifies both shapes.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finder that delegates to [target] but returns empty for every
/// `findInCandidates` call before [succeedOnCall], then delegates to
/// [target] from [succeedOnCall] onward.
///
/// Used to differentiate the pre-loop fast-path (early calls, returns
/// empty so the helper proceeds past the early-return) from a later
/// post-loop / post-diagnose final check (call [succeedOnCall]+, returns
/// the target match so the helper must observe success).
class FlipFinder extends Finder {
  FlipFinder(this.target, {this.succeedOnCall = 2});

  final Finder target;

  /// 1-based `findInCandidates` call number at which [target] starts being
  /// consulted; every earlier call returns empty.
  final int succeedOnCall;

  int evaluateCalls = 0;

  @override
  Iterable<Element> findInCandidates(Iterable<Element> candidates) {
    evaluateCalls++;
    if (evaluateCalls < succeedOnCall) {
      return const <Element>[];
    }
    return target.findInCandidates(candidates);
  }

  @override
  Iterable<Element> get allCandidates => target.allCandidates;

  @override
  String describeMatch(Plurality plurality) => target.describeMatch(plurality);

  @override
  // ignore: deprecated_member_use
  String get description =>
      'flip-empty-then(${target.toString(describeSelf: true)})';
}
