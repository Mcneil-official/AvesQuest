import 'dart:io';
import 'dart:math' as math;

import 'package:exif_reader/exif_reader.dart';
import 'package:flutter/material.dart';

class OrientedImage extends StatefulWidget {
  const OrientedImage({
    super.key,
    required this.file,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
    this.mirrorH = false,
  });

  final File file;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final bool mirrorH;

  @override
  State<OrientedImage> createState() => _OrientedImageState();
}

class _OrientedImageState extends State<OrientedImage> {
  int _orientation = 1;

  @override
  void initState() {
    super.initState();
    _readOrientation();
  }

  @override
  void didUpdateWidget(OrientedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path ||
        oldWidget.mirrorH != widget.mirrorH) {
      _orientation = 1;
      _readOrientation();
    }
  }

  static const String _orientationKey = 'Image Orientation';

  Future<void> _readOrientation() async {
    try {
      final bytes = await widget.file.readAsBytes();
      final exif = await readExifFromBytes(bytes);
      final tag = exif.tags[_orientationKey];
      if (tag != null) {
        final v = tag.values.firstAsInt();
        if (v >= 1 && v <= 8) {
          if (mounted) setState(() => _orientation = v);
        }
      }
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final exifTransform = _transformForOrientation(_orientation);
    final mirrorTransform = widget.mirrorH
        ? (Matrix4.identity()..scaleByDouble(-1, 1, 1, 1))
        : Matrix4.identity();

    return Transform(
      alignment: Alignment.center,
      transform: exifTransform * mirrorTransform,
      child: Image.file(
        widget.file,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: widget.errorBuilder,
      ),
    );
  }

  static Matrix4 _transformForOrientation(int orientation) {
    switch (orientation) {
      case 1:
        return Matrix4.identity();
      case 2:
        return Matrix4.identity()..scaleByDouble(-1, 1, 1, 1);
      case 3:
        return Matrix4.identity()..rotateZ(math.pi);
      case 4:
        return Matrix4.identity()..scaleByDouble(1, -1, 1, 1);
      case 5:
        return Matrix4.identity()..rotateZ(3 * math.pi / 2)..scaleByDouble(-1, 1, 1, 1);
      case 6:
        return Matrix4.identity()..rotateZ(math.pi / 2);
      case 7:
        return Matrix4.identity()..rotateZ(math.pi / 2)..scaleByDouble(-1, 1, 1, 1);
      case 8:
        return Matrix4.identity()..rotateZ(3 * math.pi / 2);
      default:
        return Matrix4.identity();
    }
  }
}
