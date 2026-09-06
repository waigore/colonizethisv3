// Scenario batches for TechTreeWidget description pins (Refs #4305).

export 'tech_tree_widget_description_batches_shared.dart';
import 'tech_tree_widget_description_batches_cases_a.dart';
import 'tech_tree_widget_description_batches_cases_b.dart';
import 'tech_tree_widget_description_batches_shared.dart';

const List<TechTreeDescriptionBatch> techTreeDescriptionBatches =
    <TechTreeDescriptionBatch>[
  ...techTreeDescriptionBatchesA,
  ...techTreeDescriptionBatchesB,
];
