import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readRecordedFileBytes(String path) =>
    File(path).readAsBytes();
