import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'image_picker_helper.dart';

class AddArticleScreen extends StatefulWidget {
  const AddArticleScreen({super.key});

  @override
  State<AddArticleScreen> createState() => _AddArticleScreenState();
}

class _AddArticleScreenState extends State<AddArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  final _dio = Dio();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  String _selectedCategory = 'Cremas Faciales';
  final List<String> _categories = [
    'Cremas Faciales',
    'Cremas Corporales',
    'Protectores Labiales',
    'Aceites Esenciales',
    'Cuidado y Spa',
    'Otros',
  ];

  List<PlatformSelectedImage> _selectedFiles = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _editFileName(int index) {
    final item = _selectedFiles[index];
    final nameWithoutExt = item.customName.contains('.')
        ? item.customName.substring(0, item.customName.lastIndexOf('.'))
        : item.customName;
    final ext = item.customName.contains('.')
        ? item.customName.substring(item.customName.lastIndexOf('.'))
        : '';
        
    final controller = TextEditingController(text: nameWithoutExt);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renombrar Imagen', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nombre del archivo',
                  border: OutlineInputBorder(),
                ),
              ),
              if (ext.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Extensión: $ext',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  setState(() {
                    item.customName = '$newName$ext';
                  });
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // Open native browser file input to select multiple images
  void _pickImages() {
    pickImagesPlatform((images) {
      setState(() {
        _selectedFiles.addAll(images);
        // Limit to maximum 8 images
        if (_selectedFiles.length > 8) {
          _selectedFiles = _selectedFiles.sublist(0, 8);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se ha limitado la selección a un máximo de 8 imágenes.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    });
  }

  // Handle uploading images and saving the article
  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFiles.length < 2 || _selectedFiles.length > 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes seleccionar entre 2 y 8 imágenes. Seleccionadas: ${_selectedFiles.length}'),
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
      if (token == null) throw Exception("Usuario no autenticado");

      // 1. Upload images as multipart form-data organized in product folder inside 'tienda/'
      final formData = FormData();
      formData.fields.add(const MapEntry("section", "tienda"));
      final productName = _nameController.text.trim();
      if (productName.isNotEmpty) {
        formData.fields.add(MapEntry("product_name", productName));
      }
      for (var namedFile in _selectedFiles) {
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
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception("Error al subir las imágenes al servidor.");
      }

      final List<String> imageUrls = List<String>.from(uploadResponse.data);

      // 2. Submit the product details with the uploaded image URLs
      final originalPriceText = _originalPriceController.text.trim();
      final double? originalPrice = originalPriceText.isNotEmpty
          ? double.tryParse(originalPriceText)
          : null;

      final articlePayload = {
        "name": _nameController.text.trim(),
        "description": _descController.text.trim(),
        "price": double.parse(_priceController.text.trim()),
        "original_price": originalPrice,
        "stock": int.parse(_stockController.text.trim()),
        "category": _selectedCategory,
        "image_urls": imageUrls,
      };

      final createResponse = await _dio.post(
        "http://localhost:8000/articles/",
        data: articlePayload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (createResponse.statusCode == 201) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('¡Artículo creado con éxito! 🎉'), backgroundColor: Colors.green),
        );
        navigator.pop(true); // Return to catalog and indicate change
      } else {
        throw Exception("Error al crear el artículo.");
      }
    } catch (e) {
      String errMsg = e.toString().replaceAll('Exception: ', '');
      if (e is DioException && e.response != null) {
        errMsg = e.response?.data['detail'] ?? errMsg;
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $errMsg'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Nuevo Producto - Relaxbell', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFBE185D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles del Producto',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del Artículo',
                          prefixIcon: const Icon(Icons.shopping_bag_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa un nombre' : null,
                      ),
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Descripción',
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa una descripción' : null,
                      ),
                      const SizedBox(height: 16),
                      // Price, Original Price & Stock
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Precio Actual (\$)',
                                prefixIcon: const Icon(Icons.attach_money),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Ingresa el precio';
                                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                  return 'Precio debe ser > 0';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _originalPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Precio Original (\$ tachado)',
                                hintText: 'Opcional (si tiene descuento)',
                                prefixIcon: const Icon(Icons.money_off_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final orig = double.tryParse(value);
                                  if (orig == null || orig <= 0) {
                                    return 'Debe ser > 0';
                                  }
                                  final currentPrice = double.tryParse(_priceController.text);
                                  if (currentPrice != null && orig <= currentPrice) {
                                    return 'Debe ser mayor al actual';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Stock Disponible',
                                prefixIcon: const Icon(Icons.inventory_2_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Ingresa el stock';
                                if (int.tryParse(value) == null || int.parse(value) < 0) {
                                  return 'Stock no puede ser negativo';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Category
                      DropdownButtonFormField<String>(
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
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Imágenes del Artículo',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sube entre 2 y 8 imágenes. Seleccionadas: ${_selectedFiles.length}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Elegir Imágenes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[50],
                              foregroundColor: Colors.blue,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Image Preview List
                      _selectedFiles.isEmpty
                          ? Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                border: Border.all(color: Colors.grey[200]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Ninguna imagen seleccionada', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isWide ? 4 : 2,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _selectedFiles.length,
                              itemBuilder: (context, index) {
                                final namedFile = _selectedFiles[index];
                                final objectUrl = namedFile.objectUrl;
                                return Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[300]!),
                                        image: DecorationImage(
                                          image: NetworkImage(objectUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    if (index == 0)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.star, color: Colors.white, size: 12),
                                              SizedBox(width: 4),
                                              Text(
                                                'Principal',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                namedFile.customName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            InkWell(
                                              onTap: () => _editFileName(index),
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedFiles.removeAt(index).dispose();
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    )
                                  ],
                                );
                              },
                            ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveArticle,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Guardar Artículo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Subiendo imágenes y creando artículo...',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}

