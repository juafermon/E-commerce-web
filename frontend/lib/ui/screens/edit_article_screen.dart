// lib/ui/screens/edit_article_screen.dart
// Pantalla exclusiva para Administradores que permite modificar toda la información de un artículo:
// Nombre, precio, descuento (en porcentaje), stock, categoría, descripción, disponibilidad,
// y agregar/remover imágenes en la misma carpeta creada para el producto.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/article_model.dart';
import '../../data/services/catalog_service.dart';
import '../widgets/safe_network_image.dart';
import '../theme/app_colors.dart';
import 'image_picker_helper.dart';

class EditArticleScreen extends StatefulWidget {
  final ArticleModel article;

  const EditArticleScreen({
    super.key,
    required this.article,
  });

  @override
  State<EditArticleScreen> createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  final _dio = Dio();
  final CatalogService _catalogService = CatalogService();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _basePriceController;
  late TextEditingController _discountPercentController;
  late TextEditingController _stockController;

  late String _selectedCategory;
  late bool _isAvailable;

  final List<String> _categories = [
    'Cremas Faciales',
    'Cremas Corporales',
    'Protectores Labiales',
    'Aceites Esenciales',
    'Cuidado y Spa',
    'Otros',
  ];

  // Imágenes existentes del producto
  late List<String> _existingImages;
  final List<String> _removedImages = [];

  // Nuevas imágenes seleccionadas para subir
  final List<PlatformSelectedImage> _newImages = [];

  bool _isSaving = false;
  String? _detectedFolder;

  @override
  void initState() {
    super.initState();
    final article = widget.article;

    _nameController = TextEditingController(text: article.name);
    _descController = TextEditingController(text: article.description ?? '');

    // Calcular precio base y descuento inicial
    if (article.hasDiscount && article.originalPrice != null) {
      _basePriceController = TextEditingController(
        text: article.originalPrice!.toStringAsFixed(0),
      );
      _discountPercentController = TextEditingController(
        text: article.discountPercentage.toString(),
      );
    } else {
      _basePriceController = TextEditingController(
        text: article.price.toStringAsFixed(0),
      );
      _discountPercentController = TextEditingController(text: '0');
    }

    _stockController = TextEditingController(text: article.stock.toString());
    _isAvailable = article.isAvailable;

    // Configurar categorías
    _selectedCategory = article.category ?? 'Cremas Faciales';
    if (!_categories.contains(_selectedCategory)) {
      _categories.insert(0, _selectedCategory);
    }

    // Copiar lista de imágenes existentes
    _existingImages = [];
    if (article.imageUrls.isNotEmpty) {
      _existingImages.addAll(article.imageUrls);
    } else if (article.imageUrl != null && article.imageUrl!.isNotEmpty) {
      _existingImages.add(article.imageUrl!);
    }

    // Detectar la carpeta existente de almacenamiento
    _detectStorageFolder();
  }

  void _detectStorageFolder() {
    for (final url in _existingImages) {
      final folder = _extractFolderFromUrl(url);
      if (folder != null) {
        _detectedFolder = folder;
        break;
      }
    }
  }

  /// Extrae la ruta de la carpeta (ej: "tienda/crema_facial_hidratante") desde la URL de Supabase Storage
  String? _extractFolderFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIdx = segments.indexOf('images');
      if (bucketIdx != -1 && segments.length > bucketIdx + 2) {
        return segments.sublist(bucketIdx + 1, segments.length - 1).join('/');
      }
      final tiendaIdx = segments.indexOf('tienda');
      if (tiendaIdx != -1 && segments.length > tiendaIdx + 1) {
        return segments.sublist(tiendaIdx, segments.length - 1).join('/');
      }
      final servIdx = segments.indexOf('servicios');
      if (servIdx != -1 && segments.length > servIdx + 1) {
        return segments.sublist(servIdx, segments.length - 1).join('/');
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _basePriceController.dispose();
    _discountPercentController.dispose();
    _stockController.dispose();
    for (var img in _newImages) {
      img.dispose();
    }
    super.dispose();
  }

  // Abre el selector de imágenes de la plataforma
  void _pickMoreImages() {
    pickImagesPlatform((images) {
      setState(() {
        final totalAllowed = 10 - (_existingImages.length + _newImages.length);
        if (totalAllowed <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Límite alcanzado: máximo 10 imágenes por producto.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        if (images.length > totalAllowed) {
          _newImages.addAll(images.sublist(0, totalAllowed));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Se agregaron solo $totalAllowed imágenes para no superar el límite de 10.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          _newImages.addAll(images);
        }
      });
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      final removed = _existingImages.removeAt(index);
      _removedImages.add(removed);
    });
  }

  void _makeExistingPrimary(int index) {
    if (index == 0) return;
    setState(() {
      final item = _existingImages.removeAt(index);
      _existingImages.insert(0, item);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      final img = _newImages.removeAt(index);
      img.dispose();
    });
  }

  /// Calcula el precio final de venta basado en el precio base y el descuento
  double _calculateFinalPrice() {
    final base = double.tryParse(_basePriceController.text.trim()) ?? 0.0;
    final discount = int.tryParse(_discountPercentController.text.trim()) ?? 0;
    if (discount <= 0) return base;
    if (discount >= 100) return 0.0;
    return (base * (1.0 - (discount / 100.0))).roundToDouble();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final totalImages = _existingImages.length + _newImages.length;
    if (totalImages < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El producto debe tener al menos 1 imagen.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final String? token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception("Sesión expirada o usuario no autenticado.");

      // 1. Subir nuevas imágenes si hay seleccionadas
      final List<String> newlyUploadedUrls = [];
      if (_newImages.isNotEmpty) {
        final formData = FormData();
        formData.fields.add(const MapEntry("section", "tienda"));

        // Reutilizar la carpeta existente del producto o usar el nombre actual
        if (_detectedFolder != null && _detectedFolder!.isNotEmpty) {
          formData.fields.add(MapEntry("folder_path", _detectedFolder!));
        } else {
          formData.fields.add(MapEntry("product_name", _nameController.text.trim()));
        }

        for (var namedFile in _newImages) {
          final bytes = await namedFile.readBytes();
          formData.files.add(MapEntry(
            "files",
            MultipartFile.fromBytes(bytes, filename: namedFile.customName),
          ));
        }

        final uploadResponse = await _dio.post(
          "http://localhost:8000/articles/upload-images",
          data: formData,
          options: Options(
            headers: {"Authorization": "Bearer $token"},
          ),
        );

        if (uploadResponse.statusCode == 200) {
          newlyUploadedUrls.addAll(List<String>.from(uploadResponse.data));
        } else {
          throw Exception("Error al subir las nuevas imágenes.");
        }
      }

      // Lista consolidada final de imágenes
      final List<String> finalImageUrls = [..._existingImages, ...newlyUploadedUrls];

      // 2. Calcular precios y descuentos
      final basePrice = double.parse(_basePriceController.text.trim());
      final discountPercent = int.parse(_discountPercentController.text.trim());

      double sellingPrice;
      double? originalPrice;

      if (discountPercent > 0) {
        sellingPrice = (basePrice * (1.0 - (discountPercent / 100.0))).roundToDouble();
        originalPrice = basePrice;
      } else {
        sellingPrice = basePrice;
        originalPrice = null;
      }

      // 3. Preparar payload y enviar PUT
      final articlePayload = {
        "name": _nameController.text.trim(),
        "description": _descController.text.trim(),
        "price": sellingPrice,
        "original_price": originalPrice,
        "stock": int.parse(_stockController.text.trim()),
        "category": _selectedCategory,
        "image_urls": finalImageUrls,
        "is_available": _isAvailable,
      };

      final updatedArticle = await _catalogService.updateArticle(
        articleId: widget.article.id,
        payload: articlePayload,
        token: token,
      );

      // 4. Limpieza en segundo plano de imágenes eliminadas
      if (_removedImages.isNotEmpty) {
        _catalogService.deleteImages(_removedImages, token);
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('¡Artículo actualizado exitosamente! 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      // Devolver el artículo actualizado
      navigator.pop(updatedArticle);
    } catch (e) {
      String errMsg = e.toString().replaceAll('Exception: ', '');
      if (e is DioException && e.response != null) {
        errMsg = e.response?.data['detail'] ?? errMsg;
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $errMsg'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double finalPrice = _calculateFinalPrice();
    final int discount = int.tryParse(_discountPercentController.text.trim()) ?? 0;
    final double basePrice = double.tryParse(_basePriceController.text.trim()) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Artículo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFFBE185D),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveChanges,
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Guardar cambios',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 860),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      spreadRadius: 2,
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBE185D).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit_note, color: Color(0xFFBE185D), size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Modificar Producto',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                Text(
                                  'ID: #${widget.article.id} · Solo visible para Administradores',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Nombre del Artículo
                      const Text(
                        'Información Básica',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del Artículo',
                          hintText: 'Ej: Crema Hidratante & Nutritiva',
                          prefixIcon: const Icon(Icons.shopping_bag_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'El nombre es obligatorio' : null,
                      ),
                      const SizedBox(height: 16),

                      // Categoría y Disponibilidad
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Categoría',
                                prefixIcon: const Icon(Icons.category_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _categories.map((cat) {
                                return DropdownMenuItem(value: cat, child: Text(cat));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Stock Disp.',
                                prefixIcon: const Icon(Icons.inventory_2_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Ingresa el stock';
                                if (int.tryParse(value) == null || int.parse(value) < 0) {
                                  return 'No negativo';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Switch de Disponibilidad
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isAvailable ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isAvailable ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isAvailable ? Icons.check_circle_outline : Icons.pause_circle_outline,
                                  color: _isAvailable ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _isAvailable ? 'Producto Activo en Catálogo' : 'Producto Pausado (Oculto)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _isAvailable ? Colors.green[800] : Colors.red[800],
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isAvailable,
                              activeThumbColor: Colors.green,
                              onChanged: (val) => setState(() => _isAvailable = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Sección de Precios y Descuentos
                      const Text(
                        'Precios y Descuento',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _basePriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Precio Base / Normal (\$)',
                                hintText: 'Ej: 250000',
                                prefixIcon: const Icon(Icons.attach_money),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Ingresa el precio base';
                                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                  return 'Debe ser > 0';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _discountPercentController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Descuento (%)',
                                hintText: '0 - 99',
                                prefixIcon: const Icon(Icons.percent_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Ingresa %';
                                final val = int.tryParse(value);
                                if (val == null || val < 0 || val >= 100) {
                                  return 'Entre 0 y 99';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Botones rápidos de descuento
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [0, 10, 15, 20, 25, 30, 40, 50].map((pct) {
                          final isSelected = discount == pct;
                          return ChoiceChip(
                            label: Text(pct == 0 ? 'Sin desc.' : '$pct%'),
                            selected: isSelected,
                            selectedColor: AppColors.discountBadge,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _discountPercentController.text = pct.toString();
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Tarjeta interactiva de Vista Previa de Precio
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: discount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: discount > 0 ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              discount > 0 ? Icons.local_offer_rounded : Icons.info_outline,
                              color: discount > 0 ? AppColors.discountBadge : AppColors.neutral500,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: discount > 0
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              ArticleModel.formatPrice(basePrice),
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 14,
                                                color: AppColors.neutral400,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              ArticleModel.formatPrice(finalPrice),
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.neutral900,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.discountBadge,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '-$discount%',
                                                style: const TextStyle(
                                                  fontFamily: 'DM Sans',
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Ahorro para el comprador: ${ArticleModel.formatPrice(basePrice - finalPrice)}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'Precio de venta final: ${ArticleModel.formatPrice(finalPrice)} (Sin descuento activo)',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.neutral800),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Descripción del Producto
                      const Text(
                        'Descripción del Producto',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe las características, beneficios e ingredientes...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Gestión de Imágenes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Imágenes del Artículo',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total: ${_existingImages.length + _newImages.length} (mínimo 1, máximo 10)',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              if (_detectedFolder != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Carpeta del producto: $_detectedFolder',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFBE185D), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickMoreImages,
                            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                            label: const Text('Agregar Fotos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Cuadrícula de Imágenes Existentes
                      if (_existingImages.isNotEmpty) ...[
                        const Text(
                          'Imágenes Actuales:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: List.generate(_existingImages.length, (index) {
                            final url = _existingImages[index];
                            final isPrimary = index == 0;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isPrimary ? const Color(0xFFBE185D) : Colors.grey[300]!,
                                      width: isPrimary ? 2.5 : 1.0,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SafeNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      placeholder: const Center(
                                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                      ),
                                      errorWidget: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                if (isPrimary)
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFBE185D),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Principal',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                if (!isPrimary)
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: InkWell(
                                      onTap: () => _makeExistingPrimary(index),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Hacer principal',
                                          style: TextStyle(color: Colors.white, fontSize: 9),
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: InkWell(
                                    onTap: () => _removeExistingImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Cuadrícula de Nuevas Imágenes Seleccionadas
                      if (_newImages.isNotEmpty) ...[
                        const Text(
                          'Nuevas Imágenes por Subir:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: List.generate(_newImages.length, (index) {
                            final item = _newImages[index];
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.blue[300]!, width: 2),
                                    color: Colors.blue[50],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB), size: 32),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                        child: Text(
                                          item.customName,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: InkWell(
                                    onTap: () => _removeNewImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                      ],

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Botones de Acción
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: _isSaving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancelar', style: TextStyle(color: Colors.black87)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveChanges,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                              _isSaving ? 'Guardando...' : 'Guardar Cambios',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBE185D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 18),
                        Text(
                          'Actualizando artículo...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
