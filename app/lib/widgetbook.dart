// Widgetbook entry: `flutter run -t lib/widgetbook.dart`.
// Story catalog lives in [widgetbook/catalog.dart] (excluded from app coverage gate).
import 'widgetbook/catalog.dart' as widgetbook_catalog;

void main() => widgetbookMain();

/// Same as [main]; callable from tests with binding initialized.
void widgetbookMain() => widgetbook_catalog.bootstrapWidgetbook();
