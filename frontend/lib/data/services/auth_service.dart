// auth_service.dart
// Este servicio se encarga de manejar la autenticación con el backend, 
// incluyendo el inicio de sesión, almacenamiento seguro del token JWT y cierre de sesión.

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_model.dart';

class AuthService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  // URL para emulador de Android (10.0.2.2 apunta al localhost de tu PC)
  // Si pruebas en iOS o dispositivo físico, usa la IP de tu PC (Ej: 192.168.1.X:8000)
  //final String _baseUrl = "http://10.0.2.2:8000/auth/login";
  final String _baseUrl = "http://localhost:8000/auth/login";

  /// Envía las credenciales al backend y guarda el token si es exitoso
  Future<bool> login(String username, String password) async {
    try {
      // FastAPI requiere las credenciales como Form Data para OAuth2
      final formData = FormData.fromMap({
        'username': username,
        'password': password,
      });

      final response = await _dio.post(_baseUrl, data: formData);

      if (response.statusCode == 200) {
        // Parseamos la respuesta al modelo de Dart
        final tokenData = AuthTokenModel.fromJson(response.data);
        
        // Guardamos el token de forma segura en el dispositivo
        await _storage.write(key: 'jwt_token', value: tokenData.accessToken);
        return true;
      }
      return false;
    } on DioException catch (e) {
      // Captura errores del backend (401 Unauthorized, etc.)
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Error en el servidor');
      }
      throw Exception('No se pudo conectar al servidor');
    }
  }

  /// Recupera el token guardado para saber si el usuario ya está logueado
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  /// Borra el token (Cerrar Sesión)
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }
}