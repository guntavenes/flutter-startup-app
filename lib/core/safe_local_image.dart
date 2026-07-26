import 'dart:io';

import 'package:flutter/material.dart';

class SafeLocalImage extends StatelessWidget {
  const SafeLocalImage({
    required this.imagePath,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    super.key,
  });

  final String? imagePath;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;

  bool _isUsableLocalImage(String? path) {
    if (path == null || path.trim().isEmpty) {
      return false;
    }

    // Başka telefondan gelen URL veya geçersiz değerleri local dosya olarak açma.
    final uri = Uri.tryParse(path);

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return false;
    }

    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUsableLocalImage(imagePath)) {
      return fallback;
    }

    return Image.file(
      File(imagePath!),
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
