import 'dart:typed_data';

Future<Uint8List> readRecordedFileBytes(String path) => throw UnsupportedError(
  'Recorded files are not supported on this platform.',
);

Future<Uint8List> readSelectedFileBytes(Uint8List? bytes, String? path) async {
  if (bytes != null) return bytes;
  throw UnsupportedError('Selected files are not supported on this platform.');
}

Future<String> createVoiceRecordingPath(String extension) =>
    throw UnsupportedError(
      'Voice recording is not supported on this platform.',
    );

Future<bool> normalizeRecordedM4aBrand(String path) async => false;

Future<void> deleteRecordedFile(String path) async {}
