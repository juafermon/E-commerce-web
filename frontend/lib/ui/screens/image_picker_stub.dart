import 'dart:typed_data';

class PlatformSelectedImage {
  String customName;
  String get objectUrl => '';

  PlatformSelectedImage(this.customName);

  Future<Uint8List> readBytes() async {
    return Uint8List(0);
  }

  void dispose() {}
}

void pickImagesPlatform(void Function(List<PlatformSelectedImage>) onSelected) {
  // Stub for non-web environments (e.g. headless tests)
}
