import 'package:flutter/material.dart';
import '../models/article_model.dart';

// Estructura interna para representar un elemento dentro del carrito
class CartItem {
  final ArticleModel article;
  int quantity;

  CartItem({required this.article, this.quantity = 1});
}

class CartProvider extends ChangeNotifier {
  // Lista en memoria de los productos en el carrito
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // Calcula el precio total acumulado del carrito
  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + (item.article.price * item.quantity));
  }

  // Cuenta la cantidad total de artículos
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  // Agrega un producto o incrementa su cantidad si ya existe
  void addArticle(ArticleModel article) {
    for (var item in _items) {
      if (item.article.id == article.id) {
        if (item.quantity < article.stock) {
          item.quantity++;
          notifyListeners(); // Avisa a la interfaz gráfica que se actualice
        }
        return;
      }
    }
    _items.add(CartItem(article: article));
    notifyListeners();
  }

  // Remueve o disminuye la cantidad de un producto
  void removeArticle(int articleId) {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].article.id == articleId) {
        if (_items[i].quantity > 1) {
          _items[i].quantity--;
        } else {
          _items.removeAt(i);
        }
        break;
      }
    }
    notifyListeners();
  }

  // Vacía el carrito por completo
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}