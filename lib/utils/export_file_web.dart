import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web implementation (Flutter Web)
void exportCsvImpl(String csvContent, String filename) {
  final bytes = Uint8List.fromList(utf8.encode(csvContent));

  // Convert to JS Uint8Array
  final jsUint8Array = bytes.toJS;

  // Blob parts must be JSArray<JSAny>
  final parts = <JSAny>[jsUint8Array].toJS;

  final blob = web.Blob(parts, web.BlobPropertyBag(type: "text/csv"));
  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = "none";

  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();

  web.URL.revokeObjectURL(url);
}
