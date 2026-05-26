// lib/data/services/catalog_service.dart
import 'package:dio/dio.dart';
import '../models/article_model.dart';

class CatalogService {
  final Dio _dio = Dio();
  // Cambiado a localhost para que funcione en Chrome Web
  final String _baseUrl = "http://localhost:8000/articles/"; 

  Future<List<ArticleModel>> fetchArticles() async {
    try {
      final response = await _dio.get(_baseUrl);
      
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => ArticleModel.fromJson(json)).toList();
      } else {
        throw Exception("Error al cargar el catálogo");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }
  }
}