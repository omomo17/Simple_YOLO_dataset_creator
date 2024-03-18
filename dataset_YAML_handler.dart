import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

class DatasetYAML {
  Map datasetYAMLMap;
  File datasetYAMLFile;

  DatasetYAML(this.datasetYAMLMap, this.datasetYAMLFile);

  factory DatasetYAML.fromFolderPath(String yamlFolderPath) {
    if (DatasetYAML.exist(yamlFolderPath)) {
      final String yamlFilePath = path.join(yamlFolderPath, 'dataset.yaml');
      final file = File(yamlFilePath);
      final yamlString = file.readAsStringSync();
      final map = loadYaml(yamlString);
      if (map['names'] == null) {
        throw Exception('names key not found in dataset.yaml');
      }
      return DatasetYAML(map, file);
    } else {
      throw Exception('dataset.yaml not found at $yamlFolderPath');
    }
  }

  void addNewClassWoKey(String value){
  // datasetYAMLMapの'names'リストを変更可能なMapにコピー
  Map<String, dynamic> editableMap = Map<String, dynamic>.from(datasetYAMLMap);

  // 'names'キーに関連付けられたリストが変更可能なListであることを保証
  if (!editableMap.containsKey('names')) {
    editableMap['names'] = [];
  }
  List<dynamic> namesList = List<dynamic>.from(editableMap['names']);

  // 新しいキーを決定（最後のキーの次の値または0）
  int newKey = namesList.isNotEmpty ? namesList.length : 0;

  // 新しいデータを追加
  namesList.add({newKey.toString(): value});
  editableMap['names'] = namesList;

  // 変更を加えたMapをYAML形式の文字列に変換
  String updatedYamlString = YamlMap.wrap(editableMap).toString();

  datasetYAMLMap = editableMap;

  // ファイルに保存
  datasetYAMLFile.writeAsString(updatedYamlString);
}

  static bool exist(String folderPath) {
    final String yamlFilePath = path.join(folderPath, 'dataset.yaml');

    // ファイルが存在するか確認
    final file = File(yamlFilePath);
    if (file.existsSync()) {
      return true;
    } else {
      return false;
    }
  }

  static bool createDefaultYAML(String folder){
    // YAMLファイルに書き込む内容
    final data = {
      'path': 'path/to/my/dataset',
      'train': 'path/to/my/train/images',
      'val': 'path/to/my/val/images',
      'names': <String>[]
    };

    // ファイルを保存するディレクトリとファイル名
    final directory = folder;
    final filename = 'dataset.yaml';

    final dir = Directory(directory);
  // ディレクトリが存在するか同期的に確認
  if (!dir.existsSync()) {
    // 存在しない場合はディレクトリを同期的に作成
    dir.createSync(recursive: true);
  }

    // YAMLファイルを書き込む
    final file = File(path.join(directory, filename));
    final yamlString = YamlMap.wrap(data).toString();
    file.writeAsString(yamlString);

    return true;
  }

  @override
  String toString() => datasetYAMLMap.toString();
}