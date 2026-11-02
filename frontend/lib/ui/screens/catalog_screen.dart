// lib/ui/screens/catalog_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/article_model.dart';
import '../../data/services/catalog_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/cart_provider.dart';
import '../../data/services/wishlist_provider.dart';

import '../theme/app_colors.dart';
import '../widgets/category_sidebar.dart';
import '../widgets/product_card.dart';
import '../widgets/store_app_bar.dart';

class CatalogScreen extends StatefulWidget {
  final CartProvider cartProvider;
  final WishlistProvider wishlistProvider;
  const CatalogScreen({
    super.key,
    required this.cartProvider,
    required this.wishlistProvider,
  });

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
  static const int _limit = 12;
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
          SnackBar(
            content: Text('Error al cargar catálogo: $e'),
            backgroundColor: AppColors.error,
          ),
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

    final filteredArticles = _selectedCategory == 'Todos'
        ? _articles
        : _articles.where((a) => a.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.marfil,
      appBar: StoreAppBar(
        cartProvider: widget.cartProvider,
        wishlistProvider: widget.wishlistProvider,
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
                if (filteredArticles.length < 4 && _hasMore && !_isLoading) {
                  _loadMoreArticles();
                }
              },
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.cobreOscuro,
              backgroundColor: AppColors.blanco,
              onRefresh: () => _loadMoreArticles(refresh: true),
              child: _articles.isEmpty && _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.cobreOscuro,
                      ),
                    )
                  : _articles.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: AppSpacing.space16),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppColors.blanco,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.arena),
                                    ),
                                    child: const Icon(
                                      Icons.spa_outlined,
                                      size: 38,
                                      color: AppColors.champagne,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.space4),
                                  Text(
                                    'No hay artículos disponibles',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.carbon,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.space2),
                                  Text(
                                    'Vuelve a consultar más tarde.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: AppColors.grisCalido,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(AppSpacing.space6),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 250,
                                  childAspectRatio: 0.67,
                                  crossAxisSpacing: AppSpacing.space4 + 4,
                                  mainAxisSpacing: AppSpacing.space4 + 4,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return ProductCard(
                                      key: ValueKey('product_${filteredArticles[index].id}'),
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
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.space6,
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.cobreOscuro,
                                    ),
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
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'Nuevo Artículo',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              backgroundColor: AppColors.cobreOscuro,
              foregroundColor: AppColors.blanco,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderMd,
              ),
            )
          : null,
    );
  }
}