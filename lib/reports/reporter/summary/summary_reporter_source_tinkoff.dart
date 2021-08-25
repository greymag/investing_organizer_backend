import 'package:in_date_range/in_date_range.dart';
import 'package:investing_organizer/export/data/operations_export_data.dart';
import 'package:investing_organizer/export/data/portfolio_export_data.dart';
import 'package:investing_organizer/integrations/tinkoff/multi_tinkoff.dart';

import 'summary_reporter.dart';

class SummaryReporterSourceTinkoff implements SummaryReporterSource {
  final MultiTinkoff _tinkoff;

  SummaryReporterSourceTinkoff({
    required List<String> tokens,
    bool debug = false,
  }) : _tinkoff = MultiTinkoff(tokens: tokens, debug: debug);

  @override
  Future<PortfolioExportData> getData() => _tinkoff.loadPortfolio();

  @override
  Future<OperationsExportData> getOperations(DateRange range) {
    return _tinkoff.loadOperations(range);
  }
}
