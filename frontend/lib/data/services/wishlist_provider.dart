// lib/data/services/wishlist_provider.dart
// WishlistProvider: Estado global de la Wishlist usando ChangeNotifier,
// idéntico al patrón de CartProvider para integrarse con AnimatedBuilder.

import 'package:flutter/material.dart';
import '../models/article_model.dart';
import 'wishlist_service.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistService _service = WishlistService();

  // Lista en memoria de los artículos en la wishlist
  final List<ArticleModel> _items = [];

  // Conjunto de IDs para búsquedas O(1)
  final Set<int> _itemIds = {};

  bool _isLoading = false;
  String? _error;

  List<ArticleModel> get items => List.unmodifiable(_items);
  Set<int> get itemIds => _itemIds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _items.length;

  /// Verifica si un artículo está en la wishlist (búsqueda local O(1))
  bool contains(int articleId) => _itemIds.contains(articleId);

  /// Carga la wishlist desde el backend. Llamar después del login o al iniciar la pantalla.
  Future<void> loadWishlist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final fetched = await _service.getWishlist();
      _items.clear();
      _itemIds.clear();
      _items.addAll(fetched);
      _itemIds.addAll(fetched.map((a) => a.id));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alterna el estado de wishlist de un artículo (add/remove).
  /// Retorna true si se agregó, false si se eliminó.
  Future<bool> toggle(ArticleModel article) async {
    final wasIn = contains(article.id);
    // Optimistic update para una UI reactiva inmediata
    if (wasIn) {
      _items.removeWhere((a) => a.id == article.id);
      _itemIds.remove(article.id);
    } else {
      _items.insert(0, article);
      _itemIds.add(article.id);
    }
    notifyListeners();

    try {
      if (wasIn) {
        await _service.removeFromWishlist(article.id);
      } else {
        await _service.addToWishlist(article.id);
      }
      return !wasIn;
    } catch (e) {
      // Rollback si falla la petición al servidor
      if (wasIn) {
        _items.insert(0, article);
        _itemIds.add(article.id);
      } else {
        _items.removeWhere((a) => a.id == article.id);
        _itemIds.remove(article.id);
      }
      notifyListeners();
      rethrow;
    }
  }

  /// Limpia la wishlist localmente (para usar al cerrar sesión)
  void clear() {
    _items.clear();
    _itemIds.clear();
    _error = null;
    notifyListeners();
  }
}
