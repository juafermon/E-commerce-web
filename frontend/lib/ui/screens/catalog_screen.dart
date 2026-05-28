// lib/ui/screens/catalog_screen.dart
import 'package:flutter/material.dart';
import '../../data/models/article_model.dart';
import '../../data/services/catalog_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/cart_provider.dart';

// NUESTROS TRES COMPONENTES REUTILIZABLES
import '../widgets/category_sidebar.dart';
import '../widgets/product_card.dart';
import '../widgets/store_app_bar.dart'; // <-- Importamos el nuevo AppBar

class CatalogScreen extends StatefulWidget {
  final CartProvider cartProvider;
  const CatalogScreen({Key? key, required this.cartProvider}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final CatalogService _catalogService = CatalogService();
  final AuthService _authService = AuthService();
  
  late Future<List<ArticleModel>> _futureArticles;
  String _selectedCategory = 'Todos';

  //final List<String> _categories = ['Todos', 'Electrónica', 'Ropa y Calzado', 'Hogar', 'Deportes', 'Accesorios'];

  @override
  void initState() {
    super.initState();
    _futureArticles = _catalogService.fetchArticles();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      
      // =======================================================
      // El AppBar resumido en una sola línea
      // =======================================================
      appBar: StoreAppBar(
        cartProvider: widget.cartProvider,
        authService: _authService,
        isWeb: isWeb,
        onSessionChanged: () => setState(() {}), // Forzar redibujo de la pantalla
      ),
      // =======================================================

      body: Row(
        children: [
          if (isWeb)
            CategorySidebar(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) => setState(() => _selectedCategory = category),
            ),
          Expanded(
            child: FutureBuilder<List<ArticleModel>>(
              future: _futureArticles,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No hay artículos.'));

                final articles = _selectedCategory == 'Todos'
                    ? snapshot.data!
                    : snapshot.data!.where((a) => a.category == _selectedCategory).toList();

                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      return ProductCard(
                        article: articles[index],
                        cartProvider: widget.cartProvider,
                        authService: _authService,
                        onArticleAdded: () => setState(() {}),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}