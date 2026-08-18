import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readRecordedFileBytes(String path) =>
    File(path).readAsBytes();

Future<Uint8List> readSelectedFileBytes(Uint8List? bytes, String? path) async {
  if (bytes != null) return bytes;
  if (path == null || path.isEmpty) {
    throw StateError('The selected file has no readable path.');
  }
  return File(path).readAsBytes();
}

Future<String> createVoiceRecordingPath(String extension) async {
  final normalized = extension.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  return '${Directory.systemTemp.path}/starforge_voice_${DateTime.now().microsecondsSinceEpoch}.${normalized.isEmpty ? 'opus' : normalized}';
}

Future<bool> normalizeRecordedM4aBrand(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  if (bytes.length < 12 ||
      String.fromCharCodes(bytes.sublist(4, 8)) != 'ftyp') {
    return false;
  }
  final brand = String.fromCharCodes(bytes.sublist(8, 12));
  if (brand == 'M4A ') return true;
  if (brand != 'mp42' && brand != 'isom') return false;
  bytes.setRange(8, 12, const [0x4D, 0x34, 0x41, 0x20]);
  await file.writeAsBytes(bytes, flush: true);
  return true;
}

Future<void> deleteRecordedFile(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}
