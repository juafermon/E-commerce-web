// auth_model.dart
// Este modelo representa el token de autenticación que se recibe del backend después de iniciar sesión.
// Contiene el token de acceso y el tipo de token, y un método para convertir el JSON recibido de FastAPI a un objeto de Dart.


class AuthTokenModel {
  final String accessToken;
  final String tokenType;

  AuthTokenModel({
    required this.accessToken,
    required this.tokenType,
  });

  // Mapea el JSON del backend {"access_token": "...", "token_type": "bearer"}
  factory AuthTokenModel.fromJson(Map<String, dynamic> json) {
    return AuthTokenModel(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
    );
  }
}