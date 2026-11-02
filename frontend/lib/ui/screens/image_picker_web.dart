// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

class PlatformSelectedImage {
  final html.File _file;
  String customName;
  late final String objectUrl;

  PlatformSelectedImage(this._file, this.customName) {
    objectUrl = html.Url.createObjectUrl(_file);
  }

  Future<Uint8List> readBytes() async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(_file);
    await reader.onLoadEnd.first;
    return reader.result as Uint8List;
  }

  void dispose() {
    html.Url.revokeObjectUrl(objectUrl);
  }
}

void pickImagesPlatform(void Function(List<PlatformSelectedImage>) onSelected) {
  final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
  uploadInput.multiple = true;
  uploadInput.accept = 'image/*';
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null) {
      final list = files.map((f) => PlatformSelectedImage(f, f.name)).toList();
      onSelected(list);
    }
  });
}
