// lib/ui/screens/product_detail_screen.dart
// Pantalla dedicada e independiente para ver los detalles completos de cualquier producto del catálogo.
// No depende del estado ni de los filtros activos en la búsqueda o catálogo.

import 'package:flutter/material.dart';
import '../widgets/safe_network_image.dart';
import '../../data/models/article_model.dart';
import '../../data/models/rating_model.dart';
import '../../data/services/catalog_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/cart_provider.dart';
import '../../data/services/rating_service.dart';
import '../../data/services/wishlist_provider.dart';
import '../widgets/store_app_bar.dart';
import '../theme/app_colors.dart';
import 'edit_article_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final CartProvider cartProvider;
  final WishlistProvider wishlistProvider;
  final ArticleModel? article;
  final int? articleId;

  const ProductDetailScreen({
    super.key,
    required this.cartProvider,
    required this.wishlistProvider,
    this.article,
    this.articleId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CatalogService _catalogService = CatalogService();
  final AuthService _authService = AuthService();
  final RatingService _ratingService = RatingService();

  ArticleModel? _article;
  bool _isLoading = false;
  String? _errorMessage;

  int _selectedImageIndex = 0;
  int _quantity = 1;
  bool _isAddingToCart = false;

  // --- Estado del botón de Wishlist ---
  bool _isInWishlist = false;
  bool _isTogglingWishlist = false;

  // --- Estado del sistema de calificaciones ---
  List<RatingModel> _ratings = [];
  RatingModel? _myRating;
  bool _ratingsLoading = false;
  bool _isSubmittingRating = false;
  String? _ratingsError;
  int _selectedStars = 0;          // 0 = sin seleccionar
  final TextEditingController _commentController = TextEditingController();
  bool _isLoggedIn = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    if (widget.article != null) {
      _article = widget.article;
      _loadRatings(widget.article!.id);
    } else if (widget.articleId != null) {
      _fetchArticle(widget.articleId!);
    } else {
      _errorMessage = 'No se proporcionó información del producto.';
    }
    _checkLoginStatus();
  }

  Future<void> _checkWishlistStatus() async {
    if (_article == null) return;
    final isIn = widget.wishlistProvider.contains(_article!.id);
    if (mounted) {
      setState(() {
        _isInWishlist = isIn;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _authService.getToken();
    final role = await _authService.getUserRole();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null;
        _isAdmin = role == 'admin';
      });
    }
    // Sincronizar estado de wishlist después de conocer el login
    _checkWishlistStatus();
  }

  Future<void> _navigateToEditArticle() async {
    if (_article == null) return;
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditArticleScreen(article: _article!),
      ),
    );

    if (updated != null && mounted) {
      if (updated is ArticleModel) {
        setState(() {
          _article = updated;
          _selectedImageIndex = 0;
        });
      }
      // Refrescar datos completos desde el backend
      _fetchArticle(_article!.id);
    }
  }

  Future<void> _loadRatings(int articleId) async {
    setState(() {
      _ratingsLoading = true;
      _ratingsError = null;
    });
    try {
      final results = await Future.wait([
        _ratingService.getRatings(articleId),
        _ratingService.getMyRating(articleId),
      ]);
      final ratings = results[0] as List<RatingModel>;
      final myRating = results[1] as RatingModel?;
      if (mounted) {
        setState(() {
          _ratings = ratings;
          _myRating = myRating;
          _ratingsLoading = false;
          if (myRating != null) {
            _selectedStars = myRating.rating;
            _commentController.text = myRating.comment ?? '';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ratingsError = 'No se pudieron cargar las reseñas.';
          _ratingsLoading = false;
        });
      }
    }
  }

  Future<void> _submitRating() async {
    if (_selectedStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una puntuación de 1 a 5 estrellas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isSubmittingRating = true);
    try {
      await _ratingService.submitRating(
        articleId: _article!.id,
        rating: _selectedStars,
        comment: _commentController.text,
      );
      // Recarga la lista de reseñas y el artículo actualizado
      await _loadRatings(_article!.id);
      final updated = await _catalogService.fetchArticleById(_article!.id);
      if (mounted) {
        setState(() {
          _article = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Tu reseña fue publicada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingRating = false);
    }
  }

  Future<void> _fetchArticle(int id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched = await _catalogService.fetchArticleById(id);
      if (mounted) {
        setState(() {
          _article = fetched;
          _isLoading = false;
        });
        _loadRatings(id);
        _checkWishlistStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar el producto: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<String> _getAllImages() {
    if (_article == null) return [];
    final List<String> images = [];
    if (_article!.imageUrls.isNotEmpty) {
      images.addAll(_article!.imageUrls);
    }
    if (_article!.imageUrl != null &&
        _article!.imageUrl!.isNotEmpty &&
        !images.contains(_article!.imageUrl!)) {
      images.insert(0, _article!.imageUrl!);
    }
    return images;
  }

  Future<void> _handleAddToCart() async {
    if (_article == null || _article!.stock <= 0) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final token = await _authService.getToken();
    if (token == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para añadir productos al carrito'),
          backgroundColor: Colors.orange,
        ),
      );
      navigator.pushNamed('/login');
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final success = await widget.cartProvider.addArticleWithStockCheck(
        _article!,
        _catalogService,
        quantityToAdd: _quantity,
      );

      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              _quantity == 1
                  ? '${_article!.name} añadido al carrito'
                  : '$_quantity unidades de ${_article!.name} añadidas al carrito',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Ver Carrito',
              textColor: Colors.white,
              onPressed: () => navigator.pushNamed('/cart'),
            ),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'No hay suficiente stock disponible para añadir $_quantity unidad(es).',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error al verificar stock: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: StoreAppBar(
        cartProvider: widget.cartProvider,
        wishlistProvider: widget.wishlistProvider,
        authService: _authService,
        isWeb: isWeb,
        onSessionChanged: () {
          setState(() {});
          _checkLoginStatus();
        },
      ),
      body: _buildBody(isWeb),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _navigateToEditArticle,
              backgroundColor: const Color(0xFFBE185D),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text(
                'Editar Producto',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(bool isWeb) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando producto...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.articleId != null) {
                    _fetchArticle(widget.articleId!);
                  } else {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_article == null) {
      return const Center(child: Text('Producto no encontrado'));
    }

    final allImages = _getAllImages();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 48.0 : 16.0,
        vertical: 24.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón de navegación para regresar al catálogo
              _buildBackNavigation(),
              const SizedBox(height: 16),

              // Contenedor principal de la ficha de producto
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(isWeb ? 32.0 : 16.0),
                child: isWeb
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildGallery(allImages),
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            flex: 6,
                            child: _buildDetails(),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGallery(allImages),
                          const SizedBox(height: 24),
                          _buildDetails(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackNavigation() {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.arrow_back, size: 20, color: Colors.blue),
            SizedBox(width: 6),
            Text(
              'Volver al catálogo',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 380,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      );
    }

    // Asegurar que el índice seleccionado sea válido
    if (_selectedImageIndex >= images.length) {
      _selectedImageIndex = 0;
    }

    final currentImageUrl = images[_selectedImageIndex];
    final bool hasDiscount = _article?.hasDiscount ?? false;

    return Column(
      children: [
        // Imagen principal grande con Badge de Descuento
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(
                height: 380,
                width: double.infinity,
                color: Colors.grey[50],
                child: SafeNetworkImage(
                  imageUrl: currentImageUrl,
                  fit: BoxFit.contain,
                  placeholder: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: const Center(
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  ),
                ),
              ),
              if (hasDiscount)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.discountBadge,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '-${_article!.discountPercentage}%',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Carrusel de miniaturas si hay más de 1 imagen
        if (images.length > 1) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedImageIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SafeNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.cover,
                        placeholder: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: const Icon(
                          Icons.image_not_supported,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetails() {
    final article = _article!;
    final bool hasStock = article.stock > 0 && article.isAvailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila de Badges: Categoría, Disponibilidad y Botón de Editar para Admin
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (article.category != null && article.category!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  article.category!,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hasStock
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                hasStock ? 'En Stock (${article.stock} disp.)' : 'Agotado',
                style: TextStyle(
                  color: hasStock ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            if (!article.isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pausado (Oculto)',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            if (_isAdmin)
              ElevatedButton.icon(
                onPressed: _navigateToEditArticle,
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: const Text('Editar Producto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neutral900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Nombre del Producto
        Text(
          article.name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),

        // Precios con soporte para Descuento
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            if (article.hasDiscount) ...[
              Text(
                ArticleModel.formatPrice(article.originalPrice!),
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral400,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.neutral400,
                  decorationThickness: 1.8,
                ),
              ),
            ],
            Text(
              ArticleModel.formatPrice(article.price),
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
            ),
            if (article.hasDiscount)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.discountBadge,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-${article.discountPercentage}%',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Resumen compacto de calificación debajo del precio
        _buildRatingSummaryBadge(article),
        const SizedBox(height: 20),

        const Divider(height: 1),
        const SizedBox(height: 20),

        // Descripción
        const Text(
          'Descripción del producto',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          (article.description != null && article.description!.trim().isNotEmpty)
              ? article.description!
              : 'Este producto no cuenta con una descripción detallada en este momento.',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 28),

        const Divider(height: 1),
        const SizedBox(height: 24),

        // Selector de Cantidad y Añadir al Carrito
        if (hasStock) ...[
          Row(
            children: [
              const Text(
                'Cantidad:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: _quantity < article.stock
                          ? () => setState(() => _quantity++)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Total: ${ArticleModel.formatPrice(article.price * _quantity)}',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botón Añadir al Carrito + Botón Wishlist
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isAddingToCart ? null : _handleAddToCart,
                  icon: _isAddingToCart
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_shopping_cart, size: 20),
                  label: Text(
                    _isAddingToCart
                        ? 'Verificando inventario...'
                        : 'Añadir al Carrito',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón Wishlist (corazón animado)
              _buildWishlistButton(),
            ],
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Este artículo se encuentra actualmente agotado o no disponible.',
                    style: TextStyle(
                      color: Colors.red[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),
        const Divider(height: 1),
        const SizedBox(height: 24),

        // ═══════════════════════════════════════
        // SECCIÓN DE CALIFICACIONES Y RESEÑAS
        // ═══════════════════════════════════════
        _buildRatingsSection(),
      ],
    );
  }

  // ──────────────────────────────────────────
  // Botón de Wishlist animado (corazón)
  // ──────────────────────────────────────────
  Widget _buildWishlistButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: _isInWishlist
            ? const Color(0xFFFDF2F8)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isInWishlist
              ? const Color(0xFFBE185D).withValues(alpha: 0.5)
              : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isTogglingWishlist ? null : _handleWishlistToggle,
          borderRadius: BorderRadius.circular(11),
          child: Center(
            child: _isTogglingWishlist
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFBE185D),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: Icon(
                      _isInWishlist
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(_isInWishlist),
                      color: const Color(0xFFBE185D),
                      size: 24,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleWishlistToggle() async {
    if (_article == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Verificar si el usuario está logueado
    final token = await _authService.getToken();
    if (token == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para guardar artículos en tu lista de deseos'),
          backgroundColor: Colors.orange,
        ),
      );
      navigator.pushNamed('/login');
      return;
    }

    setState(() => _isTogglingWishlist = true);

    try {
      final wasAdded = await widget.wishlistProvider.toggle(_article!);
      if (mounted) {
        setState(() {
          _isInWishlist = wasAdded;
          _isTogglingWishlist = false;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              wasAdded
                  ? '${_article!.name} añadido a tu lista de deseos ♥'
                  : '${_article!.name} eliminado de tu lista de deseos',
            ),
            backgroundColor:
                wasAdded ? const Color(0xFFBE185D) : Colors.grey[700],
            action: wasAdded
                ? SnackBarAction(
                    label: 'Ver Wishlist',
                    textColor: Colors.white,
                    onPressed: () => navigator.pushNamed('/wishlist'),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTogglingWishlist = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ──────────────────────────────────────────
  // Badge compacto de promedio bajo el precio
  // ──────────────────────────────────────────
  Widget _buildRatingSummaryBadge(ArticleModel article) {
    if (article.ratingCount == 0) {
      return Row(
        children: [
          ...List.generate(5, (i) => Icon(Icons.star_border_rounded, size: 18, color: Colors.grey[400])),
          const SizedBox(width: 8),
          Text('Sin calificaciones aún', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      );
    }
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < article.ratingAvg.floor()) {
            return const Icon(Icons.star_rounded, size: 20, color: Colors.amber);
          } else if (i < article.ratingAvg) {
            return const Icon(Icons.star_half_rounded, size: 20, color: Colors.amber);
          } else {
            return Icon(Icons.star_border_rounded, size: 20, color: Colors.grey[400]);
          }
        }),
        const SizedBox(width: 8),
        Text(
          '${article.ratingAvg.toStringAsFixed(1)} (${article.ratingCount} reseña${article.ratingCount == 1 ? '' : 's'})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // Sección completa de calificaciones
  // ──────────────────────────────────────────
  Widget _buildRatingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calificaciones y Reseñas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 20),

        // ── Formulario para calificar ──
        _isLoggedIn
            ? _buildRatingForm()
            : _buildLoginPrompt(),

        const SizedBox(height: 28),

        // ── Lista de reseñas ──
        _buildReviewsList(),
      ],
    );
  }

  Widget _buildRatingForm() {
    final isUpdate = _myRating != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUpdate ? 'Actualizar tu reseña' : 'Califica este producto',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            isUpdate
                ? 'Puedes modificar tu puntuación y comentario.'
                : 'Tu opinión ayuda a otros compradores.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Selector interactivo de estrellas
          Row(
            children: [
              const Text('Puntuación: ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              ...List.generate(5, (i) {
                final starIndex = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStars = starIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      starIndex <= _selectedStars ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 32,
                      color: starIndex <= _selectedStars ? Colors.amber : Colors.grey[400],
                    ),
                  ),
                );
              }),
              const SizedBox(width: 12),
              if (_selectedStars > 0)
                Text(
                  ['', 'Muy malo', 'Malo', 'Regular', 'Bueno', 'Excelente'][_selectedStars],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Caja de texto para comentario
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Tu opinión (opcional)',
              hintText: '¿Qué te pareció este producto?',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Botón de envío
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmittingRating ? null : _submitRating,
              icon: _isSubmittingRating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                _isSubmittingRating
                    ? 'Publicando...'
                    : isUpdate
                        ? 'Actualizar Reseña'
                        : 'Publicar Reseña',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Inicia sesión para calificar este producto y compartir tu opinión.',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('Iniciar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_ratingsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_ratingsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(_ratingsError!, style: const TextStyle(color: Colors.redAccent)),
      );
    }
    if (_ratings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Sé el primero en reseñar este producto',
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
          ],
        ),
      );
    }
    return Column(
      children: _ratings.map((r) => _buildReviewCard(r)).toList(),
    );
  }

  Widget _buildReviewCard(RatingModel rating) {
    final isOwn = rating.id == _myRating?.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOwn ? Colors.blue.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwn ? Colors.blue.withValues(alpha: 0.2) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue.withValues(alpha: 0.15),
                child: Text(
                  rating.username[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          rating.username,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (isOwn) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Tu reseña',
                              style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatDate(rating.updatedAt ?? rating.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) => Icon(
                  i < rating.rating ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 16,
                  color: Colors.amber,
                )),
              ),
            ],
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              rating.comment!,
              style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${date.day} de ${months[date.month - 1]}. de ${date.year}';
  }
}
