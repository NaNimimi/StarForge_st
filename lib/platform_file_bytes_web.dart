import 'dart:typed_data';

import 'package:http/http.dart' as http;

Future<Uint8List> readRecordedFileBytes(String path) async {
  final response = await http.get(Uri.parse(path));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError('Recorded file returned HTTP ${response.statusCode}.');
  }
  return response.bodyBytes;
}
