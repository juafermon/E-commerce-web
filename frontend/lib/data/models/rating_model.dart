// lib/data/models/rating_model.dart
// Modelo de datos para las calificaciones y reseñas de productos,
// mapeado desde el esquema RatingResponse de FastAPI.

class RatingModel {
  final int id;
  final int articleId;
  final int userId;
  final String username;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RatingModel({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.username,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'],
      articleId: json['article_id'],
      userId: json['user_id'],
      username: json['username'] ?? 'Usuario',
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}
