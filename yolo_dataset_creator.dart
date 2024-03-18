import 'package:flutter/material.dart';
import 'dart:math';
// import 'dart:io';
// import 'package:yaml/yaml.dart';
// import 'package:path/path.dart' as path;

Rect twoPositionsToRect(Offset position1, Offset position2) {
  double left = min(position1.dx, position2.dx);
  double top = min(position1.dy, position2.dy);
  double width = (position1.dx - position2.dx).abs();
  double height = (position1.dy - position2.dy).abs();
  return Rect.fromLTWH(left, top, width, height);
}

class Bbox {
  int? cls;
  double xCenter;
  double yCenter;
  double width;
  double height;
  String string;

  Bbox._(this.cls, this.xCenter, this.yCenter, this.width, this.height)
      : string = "$cls $xCenter $yCenter $width $height";

  factory Bbox(int cls, double xCenter, double yCenter, double width, double height) {
    if (cls < 0) {
      throw ArgumentError("cls must be larger than 0");
    }
    if (!_parameterIs0to1(xCenter) || !_parameterIs0to1(yCenter) || !_parameterIs0to1(width) || !_parameterIs0to1(height)) {
      throw ArgumentError("bbox parameter must be 0 to 1");
    }
    return Bbox._(cls, xCenter, yCenter, width, height);
  }

  factory Bbox.fromString(String string) {
    var parts = string.trim().split(' ');
    var cls = int.parse(parts[0]);
    var xCenter = double.parse(parts[1]);
    var yCenter = double.parse(parts[2]);
    var width = double.parse(parts[3]);
    var height = double.parse(parts[4]);
    return Bbox(cls, xCenter, yCenter, width, height);
  }

  factory Bbox.from4Points(int cls, double x1, double y1, double x2, double y2, double imageHeight, double imageWidth){
    var height = imageHeight;
    var width = imageWidth;

    var left = x1 < x2 ? x1 : x2;
    var top = y1 < y2 ? y1 : y2;
    var right = x1 > x2 ? x1 : x2;
    var bottom = y1 > y2 ? y1 : y2;

    var xCenter = ((left + right) / 2) / width;
    var yCenter = ((top + bottom) / 2) / height;
    var bboxWidth = (right - left) / width;
    var bboxHeight = (bottom - top) / height;

    return Bbox(cls, xCenter, yCenter, bboxWidth, bboxHeight);
  }

  factory Bbox.fromRectangle(int cls, Rect rectangle, double imageHeight, double imageWidth) {
    // 左上の座標
  double x1 = rectangle.left;
  double y1 = rectangle.top;

  // 右下の座標
  double x2 = rectangle.right;
  double y2 = rectangle.bottom;
    return Bbox.from4Points(cls, x1, y1, x2, y2, imageHeight, imageWidth);
  }

  @override
  String toString() => string;

  static bool _parameterIs0to1(double value) => value >= 0.0 && value <= 1.0;

  bool changeCls(int cls) {
    if (cls < 0) {
      return false;
    }
    this.cls = cls;
    this.string = "$cls $xCenter $yCenter $width $height";
    return true;
  }

  Rect toRect(double imageHeight, double imageWidth) {
    double left = (xCenter - width / 2) * imageWidth;
    double top = (yCenter - height / 2) * imageHeight;
    double right = (xCenter + width / 2) * imageWidth;
    double bottom = (yCenter + height / 2) * imageHeight;
    return Rect.fromLTRB(left, top, right, bottom);
  }
}