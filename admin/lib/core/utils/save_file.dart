import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Downloads (web) or saves (desktop) a generated file.
Future<void> saveBytes(String fileName, List<int> bytes, String mimeType) async {
  await FilePicker.saveFile(fileName: fileName, bytes: Uint8List.fromList(bytes), mimeType: mimeType);
}
