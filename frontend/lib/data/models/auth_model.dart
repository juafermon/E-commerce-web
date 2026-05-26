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