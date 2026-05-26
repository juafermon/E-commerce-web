import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'cart_provider.dart';

class OrderService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();
  final String _baseUrl = "http://localhost:8000/orders/";

  Future<bool> createOrder(List<CartItem> cartItems, String shippingAddress) async {
    try {
      // 1. Recuperamos el Token JWT guardado en el Login
      String? token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception("Usuario no autenticado");

      // 2. Estructuramos el JSON mapeando los artículos tal como los pide FastAPI
      final List<Map<String, dynamic>> itemsJson = cartItems.map((item) => {
        "article_id": item.article.id,
        "quantity": item.quantity
      }).toList();

      final Map<String, dynamic> orderPayload = {
        "shipping_address": shippingAddress,
        "items": itemsJson
      };

      // 3. Enviamos la petición inyectando el token en las cabeceras (Bearer Token)
      final response = await _dio.post(
        _baseUrl,
        data: orderPayload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      return response.statusCode == 201;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Error al procesar la orden');
      }
      throw Exception('Error de red al conectar con el servidor');
    }
  }
}