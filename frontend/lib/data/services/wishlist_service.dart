// lib/data/services/wishlist_service.dart
// Servicio HTTP para comunicarse con los endpoints de Wishlist del backend.
// Maneja: obtener wishlist, agregar artículo, eliminar artículo, verificar estado.

import 'package:dio/dio.dart';
import 'auth_service.dart';
import '../models/article_model.dart';

class WishlistService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();
  final String _baseUrl = 'http://localhost:8000/wishlist';

  /// Retorna los headers de autorización con el token JWT guardado
  Future<Options> _authHeaders() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No autenticado');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// Obtiene todos los artículos guardados en la wishlist del usuario
  Future<List<ArticleModel>> getWishlist() async {
    try {
      final options = await _authHeaders();
      final response = await _dio.get(_baseUrl, options: options);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => _fromWishlistJson(json)).toList();
      }
      throw Exception('Error al obtener la wishlist');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw Exception('No autenticado');
      throw Exception('Error de conexión: ${e.message}');
    }
  }

  /// Verifica si un artículo específico está en la wishlist del usuario
  Future<bool> checkWishlistStatus(int articleId) async {
    try {
      final options = await _authHeaders();
      final response =
          await _dio.get('$_baseUrl/$articleId/status', options: options);
      if (response.statusCode == 200) {
        return response.data['is_in_wishlist'] as bool;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Agrega un artículo a la wishlist
  Future<void> addToWishlist(int articleId) async {
    try {
      final options = await _authHeaders();
      await _dio.post('$_baseUrl/$articleId', options: options);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Artículo no encontrado en el catálogo.');
      }
      throw Exception('Error al agregar a la wishlist: ${e.message}');
    }
  }

  /// Elimina un artículo de la wishlist
  Future<void> removeFromWishlist(int articleId) async {
    try {
      final options = await _authHeaders();
      await _dio.delete('$_baseUrl/$articleId', options: options);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('El artículo no estaba en la wishlist.');
      }
      throw Exception('Error al eliminar de la wishlist: ${e.message}');
    }
  }

  /// Convierte el JSON de la respuesta de wishlist al modelo ArticleModel
  ArticleModel _fromWishlistJson(Map<String, dynamic> json) {
    var urlsFromJson = json['image_urls'];
    List<String> urlsList = [];
    if (urlsFromJson != null) {
      urlsList = List<String>.from(urlsFromJson);
    }
    return ArticleModel(
      id: json['article_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      stock: json['stock'],
      category: json['category'],
      imageUrl: json['image_url'],
      imageUrls: urlsList,
      isAvailable: json['is_available'],
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
    );
  }
}
