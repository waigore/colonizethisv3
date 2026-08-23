// Region-chip fixture for `e2eOldWorldRegionChipAppearsSelected` pins
// (#4598 Slice B).
library;

import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:flutter/material.dart';

CtChoiceChip regionChipWithLabel(
  Widget label, {
  required bool selected,
  Key? key,
}) {
  return CtChoiceChip(
    key: key,
    label: label,
    selected: selected,
    onSelected: (_) {},
  );
}
