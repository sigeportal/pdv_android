import 'package:file_picker/file_picker.dart';

Future<String?> pickImageStorageValueImpl() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
  );

  if (result == null || result.files.isEmpty) {
    return null;
  }

  final path = result.files.single.path;
  if (path == null || path.trim().isEmpty) {
    return null;
  }

  return path;
}
