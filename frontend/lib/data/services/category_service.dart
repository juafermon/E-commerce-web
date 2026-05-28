// category_service.dart
// Este servicio se encarga de hacer la solicitud al backend para obtener la lista de categorías disponibles y sus detalles.
// Asegúrate de que el backend esté corriendo en http://localhost:8000/ para que esta URL funcione correctamente.

import 'package:dio/dio.dart';
import '../models/category_model.dart';

class CategoryService {
  final Dio _dio = Dio();
  final String _baseUrl = "http://localhost:8000/categories/"; 

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _dio.get(_baseUrl);
      
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception("Error al cargar las categorías");
      }
    } catch (e) {
      throw Exception("Error de conexión en categorías: $e");
    }
  }
}