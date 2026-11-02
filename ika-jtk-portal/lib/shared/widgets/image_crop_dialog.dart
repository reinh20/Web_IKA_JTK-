import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../app/tokens.dart';
import 'package:ika_jtk_portal/core/error_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class CropDialogResult {
  final String url;
  final String thumbnailUrl;
  final Uint8List croppedBytes;
  final String fileName;

  CropDialogResult({
    required this.url,
    this.thumbnailUrl = '',
    required this.croppedBytes,
    required this.fileName,
  });
}

class ImageCropDialog {
  static Future<CropDialogResult?> show({
    required BuildContext context,
    required Uint8List imageBytes,
    required String fileName,
    required double aspectRatio,
    required Future<dynamic> Function(Uint8List croppedBytes, String fileName) uploadFn,
  }) {
    return showDialog<CropDialogResult>(
      context: context,
      barrierDismissible: false,
      useSafeArea: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: _ImageCropContent(
          imageBytes: imageBytes,
          fileName: fileName,
          aspectRatio: aspectRatio,
          uploadFn: uploadFn,
        ),
      ),
    );
  }
}

class _ImageCropContent extends StatefulWidget {
  final Uint8List imageBytes;
  final String fileName;
  final double aspectRatio;
  final Future<dynamic> Function(Uint8List, String) uploadFn;

  const _ImageCropContent({
    required this.imageBytes,
    required this.fileName,
    required this.aspectRatio,
    required this.uploadFn,
  });

  @override
  State<_ImageCropContent> createState() => _ImageCropContentState();
}

class _ImageCropContentState extends State<_ImageCropContent> {
  ui.Image? _decodedImage;
  Rect? _cropRect;
  Size? _imgDisplaySize;
  bool _isLoadingImage = true;
  bool _isUploading = false;
  String _uploadStatusText = 'Memproses gambar...';

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    try {
      final codec = await ui.instantiateImageCodec(
        widget.imageBytes,
        targetWidth: 2048,
      );
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat gambar: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _decodedImage?.dispose();
    super.dispose();
  }

  String _getAspectLabel(double aspectRatio) {
    if ((aspectRatio - 1.0).abs() < 0.01) {
      return 'Logo Portal (1 : 1)';
    } else if ((aspectRatio - 36 / 13).abs() < 0.05) {
      return 'Portal Desktop (36 : 13)';
    } else if ((aspectRatio - 16 / 6).abs() < 0.05) {
      return 'Banner Grafis (16 : 6)';
    } else if ((aspectRatio - 4 / 3).abs() < 0.05) {
      return 'Foto Kegiatan (4 : 3)';
    } else if ((aspectRatio - 16 / 9).abs() < 0.05) {
      return 'Banner Artikel (16 : 9)';
    }
    return 'Rasio Tetap (${aspectRatio.toStringAsFixed(2)} : 1)';
  }

  void _initCropForAspect(double targetAspect, double dw, double dh) {
    if (dw <= 0 || dh <= 0) return;
    double cw = dw * 0.85;
    double ch = cw / targetAspect;
    if (ch > dh * 0.85) {
      ch = dh * 0.85;
      cw = ch * targetAspect;
    }
    _cropRect = Rect.fromLTWH(
      math.max(0, (dw - cw) / 2),
      math.max(0, (dh - ch) / 2),
      cw,
      ch,
    );
  }

  void _onMoveCrop(Offset delta, double dw, double dh) {
    if (_cropRect == null || _isUploading) return;
    double nx = (_cropRect!.left + delta.dx).clamp(0.0, math.max(0.0, dw - _cropRect!.width));
    double ny = (_cropRect!.top + delta.dy).clamp(0.0, math.max(0.0, dh - _cropRect!.height));
    setState(() {
      _cropRect = Rect.fromLTWH(nx, ny, _cropRect!.width, _cropRect!.height);
    });
  }

  void _onResizeCropSE(Offset delta, double dw, double dh) {
    if (_cropRect == null || _isUploading) return;
    double maxW = math.max(10.0, dw - _cropRect!.left);
    double maxH = math.max(10.0, dh - _cropRect!.top);
    double maxWFromH = maxH * widget.aspectRatio;
    double actualMaxW = math.min(maxW, maxWFromH);

    double nw = (_cropRect!.width + delta.dx).clamp(10.0, actualMaxW);
    double nh = nw / widget.aspectRatio;

    if (_cropRect!.left + nw > dw) {
      nw = math.max(10.0, dw - _cropRect!.left);
      nh = nw / widget.aspectRatio;
    }
    if (_cropRect!.top + nh > dh) {
      nh = math.max(10.0, dh - _cropRect!.top);
      nw = nh * widget.aspectRatio;
    }
    setState(() {
      _cropRect = Rect.fromLTWH(_cropRect!.left, _cropRect!.top, nw, nh);
    });
  }

  Future<void> _cropAndUpload() async {
    if (_decodedImage == null || _cropRect == null || _imgDisplaySize == null) return;
    setState(() {
      _isUploading = true;
      _uploadStatusText = 'Memotong gambar...';
    });

    try {
      final scaleX = _decodedImage!.width / _imgDisplaySize!.width;
      final scaleY = _decodedImage!.height / _imgDisplaySize!.height;

      final srcLeft = (_cropRect!.left * scaleX).clamp(0.0, _decodedImage!.width.toDouble());
      final srcTop = (_cropRect!.top * scaleY).clamp(0.0, _decodedImage!.height.toDouble());
      final srcWidth = (_cropRect!.width * scaleX).clamp(1.0, _decodedImage!.width.toDouble() - srcLeft);
      final srcHeight = (_cropRect!.height * scaleY).clamp(1.0, _decodedImage!.height.toDouble() - srcTop);

      final srcRect = Rect.fromLTWH(srcLeft, srcTop, srcWidth, srcHeight);

      // Hitung dimensi target terlebih dahulu (max 1080px)
      const maxOutputDim = 1080.0;
      double targetW = srcRect.width;
      double targetH = srcRect.height;
      if (targetW > maxOutputDim || targetH > maxOutputDim) {
        if (targetW > targetH) {
          targetH = (targetH * maxOutputDim) / targetW;
          targetW = maxOutputDim;
        } else {
          targetW = (targetW * maxOutputDim) / targetH;
          targetH = maxOutputDim;
        }
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // dstRect harus berukuran targetW x targetH agar seluruh srcRect (hasil crop) tergambar utuh tanpa terpotong
      final dstRect = Rect.fromLTWH(0, 0, targetW, targetH);

      canvas.drawImageRect(_decodedImage!, srcRect, dstRect, Paint());
      final picture = recorder.endRecording();

      final croppedImage = await picture.toImage(
        targetW.round(),
        targetH.round(),
      );

      if (mounted) setState(() => _uploadStatusText = 'Mengoptimasi gambar...');

      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      final imgW = croppedImage.width;
      final imgH = croppedImage.height;
      croppedImage.dispose();

      if (byteData == null) throw Exception('Gagal membuat gambar hasil potong. Silakan coba gambar lain.');
      var croppedBytes = byteData.buffer.asUint8List();

      if (mounted) setState(() => _uploadStatusText = 'Mengompresi gambar...');
      String targetFileName = widget.fileName;
      bool compressedSuccess = false;
      try {
        final isPng = targetFileName.toLowerCase().endsWith('.png');
        final targetFormat = isPng ? CompressFormat.png : CompressFormat.jpeg;
        final targetExt = isPng ? 'png' : 'jpg';

        final compressed = await FlutterImageCompress.compressWithList(
          croppedBytes,
          minWidth: 1080,
          minHeight: 1080,
          quality: 80,
          format: targetFormat,
        );
        if (compressed.isNotEmpty && compressed.length < croppedBytes.length) {
          croppedBytes = compressed;
          compressedSuccess = true;
          if (targetFileName.contains('.')) {
            final idx = targetFileName.lastIndexOf('.');
            targetFileName = '${targetFileName.substring(0, idx)}.$targetExt';
          } else {
            targetFileName = '$targetFileName.$targetExt';
          }
        }
      } catch (e) {
        // Fallback ke format JPEG jika kompresi utama gagal dan bukan PNG
        try {
          final isPng = targetFileName.toLowerCase().endsWith('.png');
          if (!isPng) {
            final compressedJpg = await FlutterImageCompress.compressWithList(
              croppedBytes,
              minWidth: 1080,
              minHeight: 1080,
              quality: 75,
              format: CompressFormat.jpeg,
            );
            if (compressedJpg.isNotEmpty && compressedJpg.length < croppedBytes.length) {
              croppedBytes = compressedJpg;
              compressedSuccess = true;
              if (targetFileName.contains('.')) {
                final idx = targetFileName.lastIndexOf('.');
                targetFileName = '${targetFileName.substring(0, idx)}.jpg';
              } else {
                targetFileName = '$targetFileName.jpg';
              }
            }
          }
        } catch (_) {}
      }

      if (!compressedSuccess) {
        try {
          final isPng = targetFileName.toLowerCase().endsWith('.png');
          final decoded = img.decodePng(croppedBytes);
          if (decoded != null) {
            if (isPng) {
              croppedBytes = Uint8List.fromList(img.encodePng(decoded, level: 6));
            } else {
              croppedBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
              if (targetFileName.contains('.')) {
                final idx = targetFileName.lastIndexOf('.');
                targetFileName = '${targetFileName.substring(0, idx)}.jpg';
              } else {
                targetFileName = '$targetFileName.jpg';
              }
            }
          }
        } catch (_) {}
      }

      if (croppedBytes.length > 10 * 1024 * 1024) {
        if (mounted) {
          setState(() => _isUploading = false);
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Gambar Terlalu Besar'),
              content: const Text(
                'Ukuran gambar setelah dipotong melebihi batas 10MB. '
                'Silakan gunakan gambar dengan resolusi lebih kecil dan coba lagi.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Mengerti'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (mounted) setState(() => _uploadStatusText = 'Mengunggah ke server...');

      final res = await widget.uploadFn(croppedBytes, targetFileName);
      String url = '';
      String thumbUrl = '';
      if (res is Map) {
        url = res['url']?.toString() ?? '';
        thumbUrl = res['thumbnailUrl']?.toString() ?? res['thumbUrl']?.toString() ?? '';
      } else if (res != null) {
        url = res.toString();
      }

      if (url.isEmpty && mounted) {
        throw Exception('Server tidak mengembalikan URL gambar. Periksa koneksi internet dan coba lagi.');
      }

      if (mounted) {
        Navigator.of(context).pop(CropDialogResult(
          url: url,
          thumbnailUrl: thumbUrl,
          croppedBytes: croppedBytes,
          fileName: targetFileName,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        // Tampilkan error dialog dengan opsi retry
        final retry = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.danger, size: 22),
                SizedBox(width: 8),
                Text('Upload Gagal'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ErrorHandler.getFriendlyMessage(e),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Kemungkinan penyebab:\n'
                  '• Koneksi internet terputus\n'
                  '• Server sedang sibuk\n'
                  '• Format/ukuran file tidak didukung',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        );
        if (retry == true && mounted) {
          _cropAndUpload();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _isUploading ? SystemMouseCursors.wait : MouseCursor.defer,
      child: Container(
        width: 900,
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF374151)),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 12)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Bar
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.crop, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Potong ${widget.fileName.contains('logo') ? 'Logo Portal' : 'Gambar'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Sesuaikan rasio dan area potong gambar sebelum diunggah',
                        style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),

          // Aspect Ratio Display Bar (Locked)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1F2937),
              border: Border(bottom: BorderSide(color: Color(0xFF374151))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Rasio Potong:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getAspectLabel(widget.aspectRatio),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Default / Terkunci',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _isUploading || _decodedImage == null || _imgDisplaySize == null
                      ? null
                      : () {
                          setState(() {
                            _initCropForAspect(
                              widget.aspectRatio,
                              _imgDisplaySize!.width,
                              _imgDisplaySize!.height,
                            );
                          });
                        },
                  icon: const Icon(Icons.refresh, size: 14, color: Color(0xFFD1D5DB)),
                  label: const Text(
                    'Reset Posisi',
                    style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF374151),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),

          // Viewport Workspace Area
          Flexible(
            child: Container(
              color: const Color(0xFF030712),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 380, maxHeight: 520),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (_isLoadingImage || _isUploading || _decodedImage == null) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary),
                            const SizedBox(height: 16),
                            Text(
                              _isUploading
                                  ? 'Mengunggah gambar hasil potong...'
                                  : 'Memuat gambar...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isUploading
                                  ? 'Mohon tunggu, sedang memproses dan mengunggah ke server...'
                                  : 'Menyiapkan area potong gambar...',
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final maxW = math.max(100.0, constraints.maxWidth - 32);
                  final maxH = math.max(100.0, constraints.maxHeight - 32);

                  final natW = _decodedImage!.width.toDouble();
                  final natH = _decodedImage!.height.toDouble();

                  double scale = math.min(maxW / natW, maxH / natH);
                  if (scale > 1.0) scale = 1.0;

                  final dw = natW * scale;
                  final dh = natH * scale;

                  if (_imgDisplaySize == null ||
                      _imgDisplaySize!.width != dw ||
                      _imgDisplaySize!.height != dh ||
                      _cropRect == null) {
                    _imgDisplaySize = Size(dw, dh);
                    _initCropForAspect(widget.aspectRatio, dw, dh);
                  }

                  if (_cropRect == null) return const SizedBox.shrink();

                  return Center(
                    child: SizedBox(
                      width: dw,
                      height: dh,
                      child: Stack(
                        children: [
                          // Underlying Dimmed Image
                          Opacity(
                            opacity: 0.4,
                            child: RawImage(
                              image: _decodedImage,
                              width: dw,
                              height: dh,
                              fit: BoxFit.fill,
                            ),
                          ),

                          // Bright Cropped Active Area
                          Positioned(
                            left: _cropRect!.left,
                            top: _cropRect!.top,
                            width: _cropRect!.width,
                            height: _cropRect!.height,
                            child: ClipRect(
                              child: OverflowBox(
                                alignment: Alignment.topLeft,
                                minWidth: dw,
                                maxWidth: dw,
                                minHeight: dh,
                                maxHeight: dh,
                                child: Transform.translate(
                                  offset: Offset(-_cropRect!.left, -_cropRect!.top),
                                  child: RawImage(
                                    image: _decodedImage,
                                    width: dw,
                                    height: dh,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Crop Frame Grid & Drag Area
                          Positioned(
                            left: _cropRect!.left,
                            top: _cropRect!.top,
                            width: _cropRect!.width,
                            height: _cropRect!.height,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onPanUpdate: (details) => _onMoveCrop(details.delta, dw, dh),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black54,
                                          blurRadius: 0,
                                          spreadRadius: 9999,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Rule of Thirds Grid Lines
                                        CustomPaint(
                                          size: Size.infinite,
                                          painter: _GridLinesPainter(),
                                        ),
                                        // Center Move Indicator Icon
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              color: Colors.black45,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.open_with,
                                              color: Colors.white70,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Bottom-Right Resize Handle (SE)
                                Positioned(
                                  right: -10,
                                  bottom: -10,
                                  child: GestureDetector(
                                    onPanUpdate: (details) =>
                                        _onResizeCropSE(details.delta, dw, dh),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2.5),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black54,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Footer Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              border: Border(top: BorderSide(color: Color(0xFF1F2937))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Geser kotak potong atau tarik titik sudut kanan bawah untuk mengatur ukuran.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF4B5563)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isUploading || _decodedImage == null ? null : _cropAndUpload,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(_isUploading ? _uploadStatusText : 'Potong & Unggah'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),  // closes MouseRegion child: Container
    );
  }
}

class _GridLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    final dx = size.width / 3;
    final dy = size.height / 3;

    // Vertical grid lines
    canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    canvas.drawLine(Offset(dx * 2, 0), Offset(dx * 2, size.height), paint);

    // Horizontal grid lines
    canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    canvas.drawLine(Offset(0, dy * 2), Offset(size.width, dy * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}