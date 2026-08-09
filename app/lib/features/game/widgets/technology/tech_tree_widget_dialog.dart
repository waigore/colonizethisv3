// Tech detail dialog for the tech tree widget. Split out of
// `tech_tree_widget.dart` to keep the host file under the repo file-size
// target (Refs #3878).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'tech_definition_detail_dialog.dart';

void showTechTreeTechDialog(
  BuildContext context, {
  required Game game,
  required Player player,
  required TechDefinition tech,
}) {
  showTechDefinitionDetailDialog(
    context,
    game: game,
    player: player,
    tech: tech,
  );
}
