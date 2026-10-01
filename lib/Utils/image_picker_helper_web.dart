import 'dart:async';
import 'dart:html' as html;

Future<String?> pickImageStorageValueImpl() async {
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement()..accept = 'image/*';

  input.onChange.listen((_) {
    final file = input.files != null && input.files!.isNotEmpty
        ? input.files!.first
        : null;

    if (file == null) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();

    reader.onLoadEnd.listen((_) {
      completer.complete(reader.result as String?);
    });

    reader.onError.listen((_) {
      completer.completeError('Falha ao ler arquivo selecionado no navegador.');
    });

    reader.readAsDataUrl(file);
  });

  input.click();
  return completer.future;
}
