import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:yolo_dataset_creator/yolo_custom_painter.dart';
import 'package:yolo_dataset_creator/yolo_dataset_creator.dart';
import 'package:yolo_dataset_creator/dataset_YAML_handler.dart';
import 'package:yolo_dataset_creator/class_listbox.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => YamlListProvider()),
        ChangeNotifierProvider(create: (context) => YoloProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Layout(),
      ),
    );
  }
}

class Layout extends StatefulWidget {
  @override
  _LayoutState createState() => _LayoutState();
}

class _LayoutState extends State<Layout> with WidgetsBindingObserver {
  List<File> _images = [];
  int _currentIndex = 0;
  Bbox? _bbox;
  Bbox? _previousBbox;
  DatasetYAML? _datasetYAML;
  final TextEditingController _controller = TextEditingController();
  Size? _screenSize;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // フォーカスノードのリスナーを追加
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    // リスナーのクリーンアップ
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  // フォーカスの状態が変わったときに呼び出される
  void _handleFocusChange() {
    setState(() {
      // フォーカスの状態が変わるとウィジェットを再構築
    });
  }

  void _addItemToYamlList() {
    final String text = _controller.text;
    if (text.isNotEmpty) {
      _datasetYAML!.addNewClassWoKey(text);
      print("updated datasetYAMLMap: ${_datasetYAML!.datasetYAMLMap}");
      _controller.clear(); // テキストフィールドをクリア
      Provider.of<YamlListProvider>(context, listen: false)
          .loadYAML(_datasetYAML!);
    }
  }

  void checkAndLoadDatasetYaml(String folderPath) async {
    if (!DatasetYAML.exist(folderPath)) {
      bool created = DatasetYAML.createDefaultYAML(folderPath);
      if (!created) {
        print("Failed to create dataset.yaml at $folderPath");
        return;
      }
      print("dataset.yaml created at $folderPath");
    }

    // 少し待機してから読み込みを行う（これを使わずにread errorを回避する方法がわからない）
    await Future.delayed(Duration(seconds: 1));

    _datasetYAML = DatasetYAML.fromFolderPath(folderPath);
    print('datasetYAMLMap: $_datasetYAML');
    Provider.of<YamlListProvider>(context, listen: false)
        .loadYAML(_datasetYAML!);
  }

  Future<void> _pickFolder() async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath != null) {
      final dir = Directory(directoryPath);
      final List<FileSystemEntity> entities = dir.listSync();
      List<File> imageFiles = entities.whereType<File>().where((item) {
        var ext = path.extension(item.path).toLowerCase();
        return ext == '.png' || ext == '.jpg' || ext == '.jpeg';
      }).toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      setState(() {
        _images = imageFiles;
        // _currentIndex = 0;
        _showNextImage(true);
      });

      checkAndLoadDatasetYaml(directoryPath);
    }
  }

  void _showNextImage(bool initialize) {
    setState(() {
      if (_images.isNotEmpty) {
        if (initialize == true) {
          _currentIndex = 0;
        } else {
          _currentIndex = (_currentIndex + 1) % _images.length;
        }
        _loadBboxes();
      }
    });
  }

  void _clickNextButton() {
    _showNextImage(false);
    Provider.of<YoloProvider>(context, listen: false).changeFlag(true);
  }

  void _updateBbox(Bbox newBbox) {
    setState(() {
      _bbox = newBbox;
    });
  }

  void _loadBboxes() {
    final File currentImage = _images[_currentIndex];
    final String imagePath = currentImage.path;
    final String txtFileName =
        path.basenameWithoutExtension(imagePath) + '.txt';
    final String txtFilePath = path.join(path.dirname(imagePath), txtFileName);
    final File txtFile = File(txtFilePath);
    if (txtFile.existsSync()) {
      final List<String> lines = txtFile.readAsLinesSync();
      final List<Bbox> bboxes = lines.map((String line) {
        final List<String> parts = line.split(' ');
        final int cls = int.parse(parts[0]);
        final double x = double.parse(parts[1]);
        final double y = double.parse(parts[2]);
        final double w = double.parse(parts[3]);
        final double h = double.parse(parts[4]);
        return Bbox(cls, x, y, w, h);
      }).toList();
      Provider.of<YoloProvider>(context, listen: false).updateBboxes(bboxes);
    } else {
      Provider.of<YoloProvider>(context, listen: false).updateBboxes([]);
    }
  }

  Future<void> _saveRectangleInfo() async {
    if (_bbox == null) {
      print("bbox is null");
      return;
    }
    if (_bbox == _previousBbox) {
      print("bbox is the same as the previous one");
      return;
    }
    final File currentImage = _images[_currentIndex];
    final String imagePath = currentImage.path;
    final String txtFileName =
        path.basenameWithoutExtension(imagePath) + '.txt';
    final String txtFilePath = path.join(path.dirname(imagePath), txtFileName);
    final File txtFile = File(txtFilePath);

    final int? selectedKey =
        Provider.of<YamlListProvider>(context, listen: false).selectedKey;
    if (selectedKey == null) {
      print("selectedKey is null");
      return;
    }

    _bbox!.changeCls(selectedKey);
    final String rectangleInfo = _bbox!.toString() + '\n';

    if (await txtFile.exists() && await txtFile.length() > 0) {
      await txtFile.writeAsString(rectangleInfo, mode: FileMode.append);
    } else {
      await txtFile.writeAsString(rectangleInfo);
    }
    print("txt file saved at $txtFilePath with content: $rectangleInfo");
    Provider.of<YoloProvider>(context, listen: false).addBbox(_bbox!);

    _previousBbox = _bbox;
  }

  @override
  Widget build(BuildContext context) {
    // 画面サイズが変更されたときに、crosshairとrectangleをリセットする
    Size screenSize = MediaQuery.of(context).size;
    if (screenSize != _screenSize) {
      _screenSize = screenSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<YoloProvider>(context, listen: false).changeFlag(true);
      });
    }

    return MaterialApp(
        home: Focus(
            autofocus: true,
            child: Shortcuts(
                shortcuts: <LogicalKeySet, Intent>{
                  LogicalKeySet(
                          LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
                      ActivateIntent(),
                  LogicalKeySet(
                          LogicalKeyboardKey.control, LogicalKeyboardKey.keyD):
                      NextIntent(),
                  LogicalKeySet(
                          LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
                      OpenFolderIntent(),
                },
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    ActivateIntent: CallbackAction<ActivateIntent>(
                      onInvoke: (intent) => _saveRectangleInfo(),
                    ),
                    NextIntent: CallbackAction<NextIntent>(
                      onInvoke: (intent) => _clickNextButton(),
                    ),
                    OpenFolderIntent: CallbackAction<OpenFolderIntent>(
                      onInvoke: (intent) => _pickFolder(),
                    ),
                  },
                  child: FocusScope(
                      child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                  child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 100.0),
                                child: Center(
                                  child: _images.isNotEmpty
                                      ? ImagePainter(
                                          imageFile: _images[_currentIndex],
                                          onBboxUpdate: (Bbox bbox) {
                                            _updateBbox(bbox);
                                          },
                                        )
                                      : const Text('No image selected'),
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                child: Center(
                                  child: YamlListComponent(),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      // focusNode: _focusNode,
                                      onFieldSubmitted: (value) {
                                        // Enterキーが押されたときの処理
                                        _addItemToYamlList();
                                      },
                                      controller: _controller,
                                      decoration: const InputDecoration(
                                        labelText: 'New Class Name',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  FloatingActionButton(
                                    onPressed: _addItemToYamlList,
                                    tooltip: 'add new class',
                                    child: const Icon(
                                      Icons.add,
                                      size: 30.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                      height: 60.0,
                                      width: 75.0,
                                      child: FloatingActionButton(
                                        onPressed: _pickFolder,
                                        tooltip: 'Open Folder',
                                        child: const Icon(
                                          Icons.folder_open,
                                          size: 30.0,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60.0,
                                      width: 75.0,
                                      child: FloatingActionButton(
                                        onPressed: _saveRectangleInfo,
                                        tooltip: 'Save Bbox',
                                        child: const Icon(
                                          Icons.save,
                                          size: 30.0,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60.0,
                                      width: 75.0,
                                      child: FloatingActionButton(
                                        onPressed: _clickNextButton,
                                        tooltip: 'Next Image',
                                        child: const Icon(
                                          Icons.navigate_next,
                                          size: 30.0,
                                        ),
                                      ),
                                    ),
                                  ]),
                            )
                          ],
                        ),
                      ),
                    ],
                  )),
                ))));

    //
  }
}

class ActivateIntent extends Intent {}

class NextIntent extends Intent {}

class OpenFolderIntent extends Intent {}

class AddItemIntent extends Intent {}
