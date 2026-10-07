// lib/main.dart
// Punto de entrada de la aplicación Flutter para la tienda virtual
// Aquí se configura el MaterialApp, las rutas y se inyecta el Carrito de Compras a las pantallas que lo necesitan.

import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/services_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/catalog_screen.dart';
import 'ui/screens/cart_screen.dart';
import 'data/services/cart_provider.dart';
import 'data/services/wishlist_provider.dart';
import 'ui/screens/wishlist_screen.dart';
import 'ui/screens/register_screen.dart';
import 'ui/screens/add_article_screen.dart';
import 'ui/screens/edit_article_screen.dart';
import 'ui/screens/product_detail_screen.dart';
import 'data/models/article_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 256 * 1024 * 1024; // 256 MB
  PaintingBinding.instance.imageCache.maximumSize = 1000;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Instancias únicas y persistentes del Carrito y la Wishlist
  static final CartProvider _globalCart = CartProvider();
  static final WishlistProvider _globalWishlist = WishlistProvider();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relaxbell - Cuidado Personal & Bienestar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFBE185D),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(cartProvider: _globalCart),
        '/home': (context) => HomeScreen(cartProvider: _globalCart),
        '/services': (context) => ServicesScreen(cartProvider: _globalCart),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/catalog': (context) => CatalogScreen(
          cartProvider: _globalCart,
          wishlistProvider: _globalWishlist,
        ),
        '/cart': (context) => CartScreen(cartProvider: _globalCart),
        '/add-article': (context) => const AddArticleScreen(),
        '/wishlist': (context) => WishlistScreen(
          cartProvider: _globalCart,
          wishlistProvider: _globalWishlist,
        ),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/product-detail') {
          final args = settings.arguments;
          ArticleModel? article;
          int? articleId;
          if (args is ArticleModel) {
            article = args;
            articleId = args.id;
          } else if (args is int) {
            articleId = args;
          }
          return MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              cartProvider: _globalCart,
              wishlistProvider: _globalWishlist,
              article: article,
              articleId: articleId,
            ),
            settings: settings,
          );
        }
        if (settings.name == '/edit-article') {
          final args = settings.arguments;
          if (args is ArticleModel) {
            return MaterialPageRoute(
              builder: (context) => EditArticleScreen(article: args),
              settings: settings,
            );
          }
        }
        return null;
      },
    );
  }
}