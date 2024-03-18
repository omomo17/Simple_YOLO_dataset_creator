import 'package:flutter/material.dart';
import 'package:yolo_dataset_creator/dataset_YAML_handler.dart';
import 'package:provider/provider.dart';

class YamlListProvider with ChangeNotifier {
  Map<int, String> _items = {};
  int? _selectedKey;

  Map<int, String> get items => _items;
  int? get selectedKey => _selectedKey;

  void loadYAML(DatasetYAML datasetYAML) {
    _items.clear();
    for (var element in datasetYAML.datasetYAMLMap["names"]) {
      element.forEach((key, value) {
        var intKey = key is String ? int.parse(key) : key;
        _items[intKey] = value;
      });
    }
    notifyListeners();
  }

  void selectItem(int key) {
    _selectedKey = key;
    notifyListeners();
  }
}

class YamlListComponent extends StatefulWidget {
  @override
  _YamlListComponentState createState() => _YamlListComponentState();
}

class _YamlListComponentState extends State<YamlListComponent> {
  @override
  Widget build(BuildContext context) {
    final yamlListProvider = Provider.of<YamlListProvider>(context);
    final items = yamlListProvider.items;
    final selectedKey = yamlListProvider.selectedKey;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final key = items.keys.elementAt(index);
              final value = items[key];
              bool isSelected = selectedKey == key;
              return Card(
                elevation: 4,
                margin: EdgeInsets.all(4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue[100]
                        : Colors.grey[100], // 選択状態で背景色を変更
                    borderRadius:
                        BorderRadius.circular(10), // Containerにも角の丸みを設定
                  ),
                  child: ListTile(
                    title: Text("$key: $value", style: TextStyle(fontSize: 18)),
                    leading: Icon(Icons.label),
                    // selectedとselectedTileColorは使用しない
                    onTap: () {
                      yamlListProvider.selectItem(key);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}