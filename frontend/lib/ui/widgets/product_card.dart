// lib/ui/widgets/product_card.dart
// Este widget representa una tarjeta de producto que se muestra en la pantalla principal. Muestra la imagen, nombre, categoría, precio y stock del artículo, y tiene un botón para añadir el producto al carrito. El botón verifica si el usuario está autenticado antes de permitir añadir al carrito, y muestra un mensaje adecuado si no lo está.
// Importamos las dependencias necesarias: Flutter Material para los widgets, ArticleModel para representar el artículo, CartProvider para manejar el estado del carrito, y AuthService para verificar la autenticación del usuario.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/article_model.dart';
import '../../data/services/cart_provider.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/catalog_service.dart';

class ProductCard extends StatefulWidget {
  final ArticleModel article;
  final CartProvider cartProvider;
  final AuthService authService;
  final VoidCallback onArticleAdded; // Callback para avisar a la pantalla principal que refresque

  const ProductCard({
    Key? key,
    required this.article,
    required this.cartProvider,
    required this.authService,
    required this.onArticleAdded,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del Producto
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: widget.article.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.article.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
            ),
          ),
          // Detalles del Producto
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.article.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.article.category ?? 'Sin categoría',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${widget.article.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text(
                      'Stock: ${widget.article.stock}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          String? token = await widget.authService.getToken();
                          if (token == null) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Inicia sesión para añadir productos'), backgroundColor: Colors.orange),
                            );
                            navigator.pushNamed('/login');
                          } else {
                            setState(() {
                              _isLoading = true;
                            });
                            try {
                              bool success = await widget.cartProvider.addArticleWithStockCheck(
                                widget.article,
                                CatalogService(),
                              );
                              if (success) {
                                widget.onArticleAdded(); // Ejecuta la actualización en el Home
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(content: Text('${widget.article.name} añadido'), duration: const Duration(seconds: 1)),
                                );
                              } else {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('No hay más stock disponible para ${widget.article.name}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error de conexión o red: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          }
                        },
                  icon: _isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_shopping_cart, size: 14),
                  label: Text(_isLoading ? 'Verificando...' : 'Añadir', style: const TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 34),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}