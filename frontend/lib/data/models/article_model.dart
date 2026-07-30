// article_model.dart
// Este modelo representa un artículo en la aplicación, con sus propiedades y un método para convertir 
// el JSON recibido de FastAPI a un objeto de Dart.
class ArticleModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? category;
  final String? imageUrl;
  final List<String> imageUrls;
  final bool isAvailable;

  ArticleModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.category,
    this.imageUrl,
    required this.imageUrls,
    required this.isAvailable,
  });

  // Transforma el JSON que viene de FastAPI a un Objeto de Dart
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    var urlsFromJson = json['image_urls'];
    List<String> urlsList = [];
    if (urlsFromJson != null) {
      urlsList = List<String>.from(urlsFromJson);
    }
    return ArticleModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(), // Evita errores si viene entero o flotante
      stock: json['stock'],
      category: json['category'],
      imageUrl: json['image_url'],
      imageUrls: urlsList,
      isAvailable: json['is_available'],
    );
  }
}