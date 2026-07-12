// Este servicio se encarga de hacer la solicitud HTTP al backend para obtener el catálogo de artículos.
// Asegúrate de que el backend esté corriendo en http://localhost:8000/ para que esta URL funcione correctamente.

// lib/data/services/catalog_service.dart
import 'package:dio/dio.dart';
import '../models/article_model.dart';

class CatalogService {
  final Dio _dio = Dio();
  // Cambiado a localhost para que funcione en Chrome Web
  final String _baseUrl = "http://localhost:8000/articles/"; 

  // Variable de clase para almacenar en caché los artículos cargados en memoria.
  static List<ArticleModel> _cache = [];

  // Método para vaciar la caché y forzar una recarga total desde el servidor.
  static void clearCache() {
    _cache.clear();
  }

  Future<List<ArticleModel>> fetchArticles({int skip = 0, int limit = 12, bool forceRefresh = false}) async {
    if (forceRefresh) {
      _cache.clear();
    }

    // Si solicitamos la primera página, no forzamos refresco y ya hay datos en caché, los devolvemos al instante.
    if (skip == 0 && _cache.isNotEmpty && !forceRefresh) {
      return _cache;
    }

    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {'skip': skip, 'limit': limit},
      );
      
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        List<ArticleModel> fetched = data.map((json) => ArticleModel.fromJson(json)).toList();
        
        if (skip == 0) {
          _cache = fetched;
        } else {
          // Concatenamos evitando elementos duplicados
          for (var item in fetched) {
            if (!_cache.any((element) => element.id == item.id)) {
              _cache.add(item);
            }
          }
        }
        return fetched;
      } else {
        throw Exception("Error al cargar el catálogo");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }
  }

  Future<ArticleModel> fetchArticleById(int articleId) async {
    try {
      final response = await _dio.get('$_baseUrl$articleId');
      if (response.statusCode == 200) {
        return ArticleModel.fromJson(response.data);
      } else {
        throw Exception("Error al cargar el artículo");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }
  }
}