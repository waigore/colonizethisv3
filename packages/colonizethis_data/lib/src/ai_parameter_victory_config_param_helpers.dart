/// Shared victory-config [AiParameter] constructors (GA tuning bounds).
///
/// SPEC/ai/ai-parameter-registry.md. Refs #3436, #4072.
library;

import 'dart:math' as math;

import 'ai_parameter.dart';

/// Victory-config `int` parameter: bounds [0, max(2000, 4 × default)].
AiParameter victoryConfigIntParam(
  String name,
  int defaultValue,
  String description,
) => AiParameter(
  name: name,
  category: AiParameterCategory.victoryConfig,
  isInteger: true,
  minValue: 0,
  maxValue: math.max(2000, 4 * defaultValue),
  defaultValue: defaultValue,
  description: description,
);

/// Victory-config `double` parameter: bounds [0.0, 4 × default].
AiParameter victoryConfigDoubleParam(
  String name,
  double defaultValue,
  String description,
) => AiParameter(
  name: name,
  category: AiParameterCategory.victoryConfig,
  isInteger: false,
  minValue: 0.0,
  maxValue: 4 * defaultValue,
  defaultValue: defaultValue,
  description: description,
);
