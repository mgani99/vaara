import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

/// Mobile/Desktop implementation
void exportCsvImpl(String csvContent, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File("${dir.path}/$filename");

  await file.writeAsString(csvContent, flush: true);
  //return file.path; // return saved file path
}
