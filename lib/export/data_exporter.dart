import 'dart:io';

abstract class DataExporter<TData> {
  const DataExporter();

  Future<File> export(String targetPath, TData data);
}
