import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/article_model.dart';
import 'package:frontend/data/services/cart_provider.dart';

void main() {
  group('CartProvider Tests', () {
    late CartProvider cart;
    final testArticle = ArticleModel(
      id: 1,
      name: 'Camiseta de Prueba',
      description: 'Descripción de prueba',
      price: 50.0,
      stock: 10,
      isAvailable: true,
      category: 'Ropa',
      imageUrls: [],
    );

    setUp(() {
      cart = CartProvider();
    });

    test('El carrito inicia vacío', () {
      expect(cart.items, isEmpty);
      expect(cart.itemCount, 0);
      expect(cart.totalAmount, 0.0);
    });

    test('Agregar artículo incrementa la cantidad y el total', () {
      cart.addArticle(testArticle);

      expect(cart.items.length, 1);
      expect(cart.itemCount, 1);
      expect(cart.totalAmount, 50.0);

      // Agregar de nuevo debe incrementar la cantidad
      cart.addArticle(testArticle);
      expect(cart.itemCount, 2);
      expect(cart.totalAmount, 100.0);
    });

    test('setItemQuantity modifica la cantidad y actualiza el total', () {
      cart.addArticle(testArticle);
      cart.setItemQuantity(testArticle.id, 5);

      expect(cart.itemCount, 5);
      expect(cart.totalAmount, 250.0);
    });

    test('removeItem elimina el artículo completamente', () {
      cart.addArticle(testArticle);
      expect(cart.items.length, 1);

      cart.removeItem(testArticle.id);
      expect(cart.items, isEmpty);
      expect(cart.itemCount, 0);
      expect(cart.totalAmount, 0.0);
    });

    test('clearCart vacía todos los artículos', () {
      cart.addArticle(testArticle);
      cart.clearCart();

      expect(cart.items, isEmpty);
      expect(cart.itemCount, 0);
    });
  });
}
