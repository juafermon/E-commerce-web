// lib/ui/widgets/safe_network_image.dart
// Componente optimizado para cargar imágenes por red en Flutter Web (CanvasKit).
// Evita el bug crítico de CanvasKit donde las texturas respaldadas por HTMLImageElement
// se vuelven negras al navegar entre pantallas, cargando los bytes directamente
// a memoria (Uint8List) y renderizándolos con Image.memory.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class SafeNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  // Caché de bytes en memoria compartida para evitar re-descargas y pérdida de texturas
  static final Map<String, Uint8List> _bytesCache = {};
  static final Map<String, Future<Uint8List?>> _inFlightRequests = {};

  static void clearCache() {
    _bytesCache.clear();
    _inFlightRequests.clear();
  }

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  Uint8List? _bytes;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant SafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final url = widget.imageUrl.trim();
    if (url.isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
      return;
    }

    // 1. Si ya se encuentra en la caché de memoria, se asigna sincrónicamente
    if (SafeNetworkImage._bytesCache.containsKey(url)) {
      if (mounted) {
        setState(() {
          _bytes = SafeNetworkImage._bytesCache[url];
          _hasError = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _hasError = false;
      });
    }

    try {
      // 2. Reutilizar peticiones en vuelo para evitar descargas duplicadas de la misma URL
      final future = SafeNetworkImage._inFlightRequests.putIfAbsent(url, () async {
        final dio = Dio();
        final response = await dio.get<List<int>>(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 10),
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final bytes = Uint8List.fromList(response.data!);
          SafeNetworkImage._bytesCache[url] = bytes;
          return bytes;
        }
        return null;
      });

      final result = await future;
      SafeNetworkImage._inFlightRequests.remove(url);

      if (mounted) {
        if (result != null) {
          setState(() {
            _bytes = result;
            _hasError = false;
          });
        } else {
          setState(() {
            _hasError = true;
          });
        }
      }
    } catch (_) {
      SafeNetworkImage._inFlightRequests.remove(url);
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
      );
    }

    if (_hasError) {
      return widget.errorWidget ??
          const Center(
            child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
          );
    }

    return widget.placeholder ??
        const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
  }
}
