import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final CropController _cropController = CropController();

  late final Future<Uint8List> _imageDataFuture;

  bool _isCropping = false;

  static const double _imageAspectRatio = 1.6;

  @override
  void initState() {
    super.initState();
    _imageDataFuture = File(widget.imagePath).readAsBytes();
  }

  Future<void> _saveCroppedImage(Uint8List croppedData) async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/item_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await file.writeAsBytes(croppedData);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: const Text('Fotoğrafı Ayarla'),
        backgroundColor: const Color(0xFFFFF5FA),
        elevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<Uint8List>(
          future: _imageDataFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 390,
                          maxHeight: 390,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            color: Colors.black,
                            child: Crop(
                              image: snapshot.data!,
                              controller: _cropController,
                              aspectRatio: _imageAspectRatio,
                              interactive: true,
                              fixCropRect: false,
                              onCropped: (result) {
                                switch (result) {
                                  case CropSuccess(:final croppedImage):
                                    _saveCroppedImage(croppedImage);

                                  case CropFailure():
                                    setState(() {
                                      _isCropping = false;
                                    });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    'Fotoğrafı iki parmağınla büyütüp küçültebilir, çerçeveye göre ayarlayabilirsin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF8A6B79),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isCropping
                          ? null
                          : () {
                              setState(() {
                                _isCropping = true;
                              });

                              _cropController.crop();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD96BA7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: _isCropping
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _isCropping ? 'Ekleniyor...' : 'Fotoğrafı Ekle',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}