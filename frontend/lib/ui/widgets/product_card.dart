// lib/ui/widgets/product_card.dart
// Este widget representa una tarjeta de producto que se muestra en la pantalla principal. Muestra la imagen, nombre, categoría, precio y stock del artículo, y tiene un botón para añadir el producto al carrito. El botón verifica si el usuario está autenticado antes de permitir añadir al carrito, y muestra un mensaje adecuado si no lo está.
// Importamos las dependencias necesarias: Flutter Material para los widgets, ArticleModel para representar el artículo, CartProvider para manejar el estado del carrito, y AuthService para verificar la autenticación del usuario.

import 'package:flutter/material.dart';
import '../../data/models/article_model.dart';
import '../../data/services/cart_provider.dart';
import '../../data/services/auth_service.dart';

class ProductCard extends StatelessWidget {
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
              child: article.imageUrl != null
                  ? Image.network(article.imageUrl!, fit: BoxFit.cover)
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
                  article.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  article.category ?? 'Sin categoría',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${article.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text(
                      'Stock: ${article.stock}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    String? token = await authService.getToken();
                    if (token == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Inicia sesión para añadir productos'), backgroundColor: Colors.orange),
                      );
                      Navigator.pushNamed(context, '/login');
                    } else {
                      cartProvider.addArticle(article);
                      onArticleAdded(); // Ejecuta la actualización en el Home
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${article.name} añadido'), duration: const Duration(seconds: 1)),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 14),
                  label: const Text('Añadir', style: TextStyle(fontSize: 11)),
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