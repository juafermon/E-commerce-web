// lib/main.dart
// Punto de entrada de la aplicación Flutter para la tienda virtual
// Aquí se configura el MaterialApp, las rutas y se inyecta el Carrito de Compras a las pantallas que lo necesitan.

import 'package:flutter/material.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/catalog_screen.dart';
import 'ui/screens/cart_screen.dart';
import 'data/services/cart_provider.dart'; // <-- Importación obligatoria

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Instancia única y persistente del Carrito de Compras
  static final CartProvider _globalCart = CartProvider();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      initialRoute: '/catalog',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/catalog': (context) => CatalogScreen(cartProvider: _globalCart), // <-- Inyectamos aquí
        '/cart': (context) => CartScreen(cartProvider: _globalCart),            // <-- Inyectamos aquí
      },
    );
  }
}