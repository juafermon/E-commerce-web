// article_model.dart
// Este modelo representa un artículo en la aplicación, con sus propiedades y un método para convertir 
// el JSON recibido de FastAPI a un objeto de Dart.
class ArticleModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double? originalPrice;
  final int stock;
  final String? category;
  final String? imageUrl;
  final List<String> imageUrls;
  final bool isAvailable;
  final double ratingAvg;
  final int ratingCount;

  ArticleModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    required this.stock,
    this.category,
    this.imageUrl,
    required this.imageUrls,
    required this.isAvailable,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
  });

  /// Indica si el producto tiene un descuento activo válido (precio original mayor al precio actual)
  bool get hasDiscount =>
      originalPrice != null && originalPrice! > price;

  /// Calcula el porcentaje de descuento redondeado (ej: 24 para -24%)
  int get discountPercentage {
    if (!hasDiscount || originalPrice == 0) return 0;
    final diff = originalPrice! - price;
    return ((diff / originalPrice!) * 100).round();
  }

  /// Formatea un valor numérico como moneda en pesos colombianos/estándar: ej $250.000
  static String formatPrice(double amount) {
    final int intVal = amount.round();
    final str = intVal.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return '\$${buffer.toString().split('').reversed.join('')}';
  }

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
      originalPrice: (json['original_price'] as num?)?.toDouble(),
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