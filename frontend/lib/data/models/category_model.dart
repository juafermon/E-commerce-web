// category_model.dart
// Este modelo representa una categoría de artículos en la aplicación, con sus propiedades y un método 
// para convertir el JSON recibido de FastAPI a un objeto de Dart.


class CategoryModel {
  final int id;
  final String name;

  CategoryModel({required this.id, required this.name});

  // Mapea el JSON que vendrá de FastAPI: {"id": 1, "name": "Electrónica"}
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
    );
  }
}