import 'dart:io';

class Environment {
  static List<String> materialVarities = [];

  static Future<void> loadMaterials() async {
    List<FileSystemEntity> temp = Directory('assets/materials').listSync();
    materialVarities = temp.map((e) => e.path.split('/').last).toList();
  }
}
