import 'dart:io';

import 'package:meta/meta.dart';
import 'package:excel/excel.dart';
import 'package:investing_organizer/export/data_exporter.dart';

abstract class ExcelExporter<TData> extends DataExporter<TData> {
  final bool cleanUpDefaultSheet;

  const ExcelExporter({this.cleanUpDefaultSheet = true});

  @override
  Future<File> export(String targetPath, TData data) async {
    final excel = Excel.createExcel();

    await writeToExcel(excel, data);

    if (cleanUpDefaultSheet && excel.sheets.length > 1) {
      excel.delete(excel.getDefaultSheet()!);
      excel.setDefaultSheet(excel.sheets.keys.first);
    }

    final bytes = excel.save()!;

    final file = File(targetPath);
    await file.writeAsBytes(bytes);
    return file;
  }

  @protected
  Future<void> writeToExcel(Excel excel, TData data);
}
