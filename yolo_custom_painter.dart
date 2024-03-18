import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yolo_dataset_creator/yolo_dataset_creator.dart';
import 'package:provider/provider.dart';

class YoloProvider with ChangeNotifier {
  bool _imageIsChanged = false;
  List<Bbox> _bboxes = [];

  bool get imageIsChanged => _imageIsChanged;
  List<Bbox> get bbox => _bboxes;

  void addBbox(Bbox bbox) {
    _bboxes.add(bbox);
    notifyListeners();
  }

  void updateBboxes(List<Bbox> bboxes) {
    _bboxes = bboxes;
    notifyListeners();
  }

  void changeFlag(bool flag) {
    _imageIsChanged = flag;
    notifyListeners();
  }
}

class ImagePainter extends StatefulWidget {
  final File imageFile;
  final Function(Bbox) onBboxUpdate;

  ImagePainter({
    Key? key,
    required this.imageFile,
    required this.onBboxUpdate,
  }) : super(key: key);

  @override
  _ImagePainterState createState() => _ImagePainterState();
}

class _ImagePainterState extends State<ImagePainter> {
  Offset? _startPosition;
  Rect? _rectangle;
  Offset? _crosshairPosition;
  Offset? _localMousePosition;
  Offset? _localMousePositionOnImage;
  RenderBox? _renderBox;
  final GlobalKey _imageKey = GlobalKey();
  Bbox? _bbox;

  void _resetRectangleAndMousePosition() {
    // setState(() {
    _startPosition = null;
    _rectangle = null;
    _crosshairPosition = null;
    _localMousePosition = null;
    _localMousePositionOnImage = null;
    // });
  }

  bool _updateLocalMousePosition(Offset globalPosition) {
    if (_imageKey.currentContext == null) return false;
    setState(() {
      _renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
      _localMousePosition = _renderBox!.globalToLocal(globalPosition);
    });
    return true;
  }

  bool _updateLocalMousePositionOnImage(Offset globalPosition) {
    if (!_updateLocalMousePosition(globalPosition)) return false;
    double dx = _localMousePosition!.dx;
    double dy = _localMousePosition!.dy;
    if (_localMousePosition!.dx < 0) {
      dx = 0;
    } else if (_localMousePosition!.dx > _renderBox!.size.width) {
      dx = _renderBox!.size.width;
    } else {
      dx = _localMousePosition!.dx;
    }
    if (_localMousePosition!.dy < 0) {
      dy = 0;
    } else if (_localMousePosition!.dy > _renderBox!.size.height) {
      dy = _renderBox!.size.height;
    } else {
      dy = _localMousePosition!.dy;
    }
    setState(() => _localMousePositionOnImage = Offset(dx, dy));
    return true;
  }

  bool _mouseIsOverImage(Offset globalPosition) {
    if (_updateLocalMousePosition(globalPosition)) {
      if (_localMousePosition!.dx >= 0 &&
          _localMousePosition!.dx <= _renderBox!.size.width &&
          _localMousePosition!.dy >= 0 &&
          _localMousePosition!.dy <= _renderBox!.size.height) {
        return true;
      }
    }
    return false;
  }

  void _updateCrosshairPosition(Offset globalPosition) {
    if (_updateLocalMousePositionOnImage(globalPosition)) {
      setState(() {
        _crosshairPosition = _localMousePositionOnImage;
      });
    } else {
      if (_crosshairPosition != null) {
        setState(() {
          _crosshairPosition = null;
        });
      }
    }
  }

  void _onPanStart(DragStartDetails details) {
    _updateCrosshairPosition(details.globalPosition);
    if (_mouseIsOverImage(details.globalPosition)) {
      // setState(() {
      _renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
      // });
      _startPosition = _renderBox!.globalToLocal(details.globalPosition);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _updateCrosshairPosition(details.globalPosition);
    setState(() {
      if (_startPosition != null && _localMousePositionOnImage != null) {
        _rectangle =
            Rect.fromPoints(_startPosition!, _localMousePositionOnImage!);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_rectangle != null) {
      setState(() {
        _bbox = Bbox.fromRectangle(
            0, _rectangle!, _renderBox!.size.height, _renderBox!.size.width);
        widget.onBboxUpdate(_bbox!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final YoloProvider yoloProvider = Provider.of<YoloProvider>(context);
    List<Bbox> _bboxes = yoloProvider.bbox;
    bool _imageIsChanged = yoloProvider.imageIsChanged;

    if (_imageIsChanged) {
      _resetRectangleAndMousePosition();
      //↓これを入れないとbuild中にsetStateが呼ばれてエラーになる
      WidgetsBinding.instance.addPostFrameCallback((_) {
        yoloProvider.changeFlag(false);
      });
    }

    return Stack(alignment: Alignment.center, children: [
      Image.file(
        widget.imageFile, // 選択された画像を表示
        key: _imageKey,
        fit: BoxFit.contain,
      ),
      Positioned.fill(
          child: MouseRegion(
        cursor: SystemMouseCursors.none,
        onHover: (event) => _updateCrosshairPosition(event.position),
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Stack(
            children: [
              // 四角形を描画するCustomPaint
              CustomPaint(
                painter: RectanglePainter(_rectangle),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              // クロスヘアを描画するCustomPaint
              CustomPaint(
                painter: CrosshairPainter(_crosshairPosition),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              CustomPaint(
                painter: DecidedBboxPainter(_bboxes),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      )),
    ]);
  }
}

class CrosshairPainter extends CustomPainter {
  final Offset? crosshairPosition;

  // constructor
  CrosshairPainter(this.crosshairPosition);

  @override
  void paint(Canvas canvas, Size size) {
    final paintCrosshair = Paint()
      // ..color = Colors.red
      ..color = const Color(0xFFFF0000)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw the crosshair
    if (crosshairPosition != null) {
      canvas.drawLine(
          Offset(0, crosshairPosition!.dy),
          Offset(size.width, crosshairPosition!.dy),
          paintCrosshair); //ここの!はnull許容型変数に対して、呼び出した時点でnullを許容しないことを示す。
      canvas.drawLine(Offset(crosshairPosition!.dx, 0),
          Offset(crosshairPosition!.dx, size.height), paintCrosshair);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // covariantはオーバーライドするメソッドの引数の型を基底クラスから変更する際に使用する。
    return true; // Always repaint for simplicity
  }
}

class RectanglePainter extends CustomPainter {
  final Rect? rectangle;

  // constructor
  RectanglePainter(this.rectangle);

  @override
  void paint(Canvas canvas, Size size) {
    final paintRectangle = Paint()
      // ..color = Colors.green
      ..color = const Color(0xFF00FF00)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw the rectangle
    if (rectangle != null) {
      canvas.drawRect(rectangle!, paintRectangle);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // covariantはオーバーライドするメソッドの引数の型を基底クラスから変更する際に使用する。
    return true; // Always repaint for simplicity
  }
}

class DecidedBboxPainter extends CustomPainter {
  final List<Bbox> bboxes;
  // final double imageHeight;
  // final double imageWidth;

  // constructor
  DecidedBboxPainter(this.bboxes);

  @override
  void paint(Canvas canvas, Size size) {
    final paintRectangle = Paint()
      // ..color = Colors.green
      ..color = const Color(0xFF0000FF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    bboxes.forEach((bbox) {
      canvas.drawRect(bbox.toRect(size.height, size.width), paintRectangle);
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // covariantはオーバーライドするメソッドの引数の型を基底クラスから変更する際に使用する。
    return true; // Always repaint for simplicity
  }
}