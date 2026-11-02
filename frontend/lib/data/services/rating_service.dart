// lib/data/services/rating_service.dart
// Servicio HTTP para consumir los endpoints de calificaciones y reseñas.
// Usa el token JWT del AuthService para las operaciones protegidas (POST).

import 'package:dio/dio.dart';
import '../models/rating_model.dart';
import 'auth_service.dart';

class RatingService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();
  final String _baseUrl = 'http://localhost:8000';

  /// Obtiene la lista pública de calificaciones de un artículo.
  Future<List<RatingModel>> getRatings(int articleId) async {
    try {
      final response = await _dio.get('$_baseUrl/articles/$articleId/ratings/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => RatingModel.fromJson(json)).toList();
      }
      throw Exception('Error al cargar las reseñas');
    } on DioException catch (e) {
      throw Exception('Error de conexión: ${e.message}');
    }
  }

  /// Obtiene la calificación propia del usuario autenticado para un artículo.
  /// Retorna null si el usuario no ha calificado este artículo.
  Future<RatingModel?> getMyRating(int articleId) async {
    final token = await _authService.getToken();
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '$_baseUrl/articles/$articleId/ratings/my-rating',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data != null) {
        return RatingModel.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      // 404 o similar: el usuario simplemente no ha calificado aún
      if (e.response?.statusCode == 404) return null;
      throw Exception('Error al verificar tu calificación: ${e.message}');
    }
  }

  /// Crea o actualiza la calificación del usuario autenticado para un artículo.
  Future<RatingModel> submitRating({
    required int articleId,
    required int rating,
    String? comment,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Debes iniciar sesión para calificar un producto');
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/articles/$articleId/ratings/',
        data: {
          'rating': rating,
          if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return RatingModel.fromJson(response.data);
      }
      throw Exception('Error al enviar la calificación');
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      throw Exception(detail ?? 'Error de conexión: ${e.message}');
    }
  }
}
