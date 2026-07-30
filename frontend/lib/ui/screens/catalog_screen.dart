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
  
  final List<ArticleModel> _articles = [];
  final ScrollController _scrollController = ScrollController();
  
  String _selectedCategory = 'Todos';
  bool _isLoading = false;
  bool _hasMore = true;
  int _skip = 0;
  static const int _limit = 12; // Carga de 12 en 12 productos
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _loadMoreArticles();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _checkAdminRole() async {
    final role = await _authService.getUserRole();
    if (mounted) {
      setState(() {
        _isAdmin = role == 'admin';
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreArticles();
      }
    }
  }

  Future<void> _loadMoreArticles({bool refresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    if (refresh) {
      _skip = 0;
      _hasMore = true;
      _articles.clear();
    }

    try {
      final newArticles = await _catalogService.fetchArticles(
        skip: _skip,
        limit: _limit,
        forceRefresh: refresh,
      );

      setState(() {
        if (newArticles.length < _limit) {
          _hasMore = false;
        }
        
        // Evitamos duplicados
        for (var article in newArticles) {
          if (!_articles.any((a) => a.id == article.id)) {
            _articles.add(article);
          }
        }
        _skip += newArticles.length;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar catálogo: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 700;

    // Filtramos localmente los artículos de acuerdo con la categoría seleccionada
    final filteredArticles = _selectedCategory == 'Todos'
        ? _articles
        : _articles.where((a) => a.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      
      // El AppBar resumido
      appBar: StoreAppBar(
        cartProvider: widget.cartProvider,
        authService: _authService,
        isWeb: isWeb,
        onSessionChanged: () {
          _checkAdminRole();
          setState(() {});
        },
      ),

      body: Row(
        children: [
          if (isWeb)
            CategorySidebar(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
                // Si cambiamos de categoría y quedan pocos elementos visibles de esa categoría, 
                // pero aún hay más productos en el servidor, cargamos la siguiente página automáticamente.
                if (filteredArticles.length < 4 && _hasMore && !_isLoading) {
                  _loadMoreArticles();
                }
              },
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadMoreArticles(refresh: true),
              child: _articles.isEmpty && _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _articles.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('No hay artículos disponibles.')),
                          ],
                        )
                      : CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(24.0),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 240,
                                  childAspectRatio: 0.68,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return ProductCard(
                                      article: filteredArticles[index],
                                      cartProvider: widget.cartProvider,
                                      authService: _authService,
                                      onArticleAdded: () => setState(() {}),
                                    );
                                  },
                                  childCount: filteredArticles.length,
                                ),
                              ),
                            ),
                            if (_isLoading)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                          ],
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/add-article').then((_) {
                  _loadMoreArticles(refresh: true);
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Artículo'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}