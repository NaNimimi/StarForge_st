import 'dart:typed_data';

import 'package:http/http.dart' as http;

Future<Uint8List> readSelectedFileBytes(Uint8List? bytes, String? path) async {
  if (bytes != null) return bytes;
  throw StateError('The browser did not provide the selected file bytes.');
}

Future<Uint8List> readRecordedFileBytes(String path) async {
  final response = await http.get(Uri.parse(path));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError('Recorded file returned HTTP ${response.statusCode}.');
  }
  return response.bodyBytes;
}

Future<String> createVoiceRecordingPath(String extension) async => '';

Future<bool> normalizeRecordedM4aBrand(String path) async => false;

Future<void> deleteRecordedFile(String path) async {}
