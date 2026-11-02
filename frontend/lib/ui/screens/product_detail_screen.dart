// lib/ui/screens/product_detail_screen.dart
// Pantalla dedicada e independiente para ver los detalles completos de cualquier producto del catálogo.
// No depende del estado ni de los filtros activos en la búsqueda o catálogo.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: AppColors.marfil,
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
              backgroundColor: AppColors.carbon,
              foregroundColor: AppColors.blanco,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderMd,
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: Text(
                'Editar Producto',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
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
                  color: AppColors.blanco,
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(
                    color: AppColors.arena.withValues(alpha: 0.7),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.carbon.withValues(alpha: 0.04),
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
      borderRadius: AppRadius.borderMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 18, color: AppColors.carbon),
            const SizedBox(width: 6),
            Text(
              'Volver al catálogo',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.carbon,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
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
          color: AppColors.marfil,
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: AppColors.arena),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 64, color: AppColors.arena),
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
          borderRadius: AppRadius.borderMd,
          child: Stack(
            children: [
              Container(
                height: 380,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                  border: Border.all(
                    color: AppColors.arena.withValues(alpha: 0.6),
                  ),
                  borderRadius: AppRadius.borderMd,
                ),
                child: SafeNetworkImage(
                  imageUrl: currentImageUrl,
                  fit: BoxFit.contain,
                  placeholder: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.cobreOscuro,
                    ),
                  ),
                  errorWidget: const Center(
                    child: Icon(Icons.broken_image, size: 48, color: AppColors.arena),
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
                    decoration: const BoxDecoration(
                      color: AppColors.cobreOscuro,
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Text(
                      '-${_article!.discountPercentage}%',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.blanco,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
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
                    duration: AppTransitions.duration,
                    curve: AppTransitions.curve,
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.blanco,
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(
                        color: isSelected ? AppColors.cobreOscuro : AppColors.arena,
                        width: isSelected ? 2.0 : 1.0,
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
                  color: AppColors.marfil,
                  borderRadius: AppRadius.borderPill,
                  border: Border.all(
                    color: AppColors.champagne.withValues(alpha: 0.8),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  article.category!.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.carbon,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hasStock
                    ? AppColors.successBg
                    : AppColors.errorBg,
                borderRadius: AppRadius.borderPill,
                border: Border.all(
                  color: hasStock
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Text(
                hasStock ? 'En Stock (${article.stock} disp.)' : 'Agotado',
                style: GoogleFonts.plusJakartaSans(
                  color: hasStock ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            if (!article.isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: AppRadius.borderPill,
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Pausado (Oculto)',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            if (_isAdmin)
              ElevatedButton.icon(
                onPressed: _navigateToEditArticle,
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: const Text('Editar Producto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.carbon,
                  foregroundColor: AppColors.blanco,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                  elevation: 0,
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Nombre del Producto
        Text(
          article.name,
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.carbon,
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grisCalido,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.grisCalido,
                  decorationThickness: 1.8,
                ),
              ),
            ],
            Text(
              ArticleModel.formatPrice(article.price),
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.carbon,
              ),
            ),
            if (article.hasDiscount)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.cobreOscuro,
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  '-${article.discountPercentage}%',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.blanco,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
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
        Text(
          'Descripción del producto',
          style: GoogleFonts.playfairDisplay(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.carbon,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          (article.description != null && article.description!.trim().isNotEmpty)
              ? article.description!
              : 'Este producto no cuenta con una descripción detallada en este momento.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            height: 1.6,
            color: AppColors.grisCalido,
          ),
        ),
        const SizedBox(height: 28),

        const Divider(height: 1),
        const SizedBox(height: 24),

        // Selector de Cantidad y Añadir al Carrito
        if (hasStock) ...[
          Row(
            children: [
              Text(
                'Cantidad:',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.carbon),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.arena),
                  borderRadius: AppRadius.borderMd,
                  color: AppColors.blanco,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16, color: AppColors.carbon),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        '$_quantity',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.carbon,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16, color: AppColors.carbon),
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.carbon,
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
                            color: AppColors.blanco,
                          ),
                        )
                      : const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(
                    _isAddingToCart
                        ? 'Verificando inventario...'
                        : 'Añadir al Carrito',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.carbon,
                    foregroundColor: AppColors.blanco,
                    minimumSize: const Size(0, 48),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderMd,
                    ),
                    elevation: 0,
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
              color: AppColors.errorBg,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Este artículo se encuentra actualmente agotado o no disponible.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.error,
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
      duration: AppTransitions.duration,
      curve: AppTransitions.curve,
      width: 50,
      height: 48,
      decoration: BoxDecoration(
        color: _isInWishlist
            ? AppColors.marfil
            : AppColors.blanco,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: _isInWishlist
              ? AppColors.cobreOscuro
              : AppColors.arena,
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isTogglingWishlist ? null : _handleWishlistToggle,
          borderRadius: AppRadius.borderMd,
          child: Center(
            child: _isTogglingWishlist
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.cobreOscuro,
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
                      color: AppColors.cobreOscuro,
                      size: 22,
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
          backgroundColor: AppColors.carbon,
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
            backgroundColor: AppColors.carbon,
            action: wasAdded
                ? SnackBarAction(
                    label: 'Ver Wishlist',
                    textColor: AppColors.blanco,
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
            backgroundColor: AppColors.error,
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
          ...List.generate(5, (i) => const Icon(Icons.star_border_rounded, size: 18, color: AppColors.arena)),
          const SizedBox(width: 8),
          Text(
            'Sin calificaciones aún',
            style: GoogleFonts.plusJakartaSans(color: AppColors.grisCalido, fontSize: 12.5),
          ),
        ],
      );
    }
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < article.ratingAvg.floor()) {
            return const Icon(Icons.star_rounded, size: 19, color: AppColors.champagne);
          } else if (i < article.ratingAvg) {
            return const Icon(Icons.star_half_rounded, size: 19, color: AppColors.champagne);
          } else {
            return const Icon(Icons.star_border_rounded, size: 19, color: AppColors.arena);
          }
        }),
        const SizedBox(width: 8),
        Text(
          '${article.ratingAvg.toStringAsFixed(1)} (${article.ratingCount} reseña${article.ratingCount == 1 ? '' : 's'})',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.carbon,
          ),
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
        Text(
          'Opiniones y Reseñas',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.carbon,
          ),
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
        color: AppColors.marfil,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.arena.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUpdate ? 'Actualizar tu reseña' : 'Califica este producto',
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.carbon,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isUpdate
                ? 'Puedes modificar tu puntuación y comentario.'
                : 'Tu opinión ayuda a otros compradores a tomar una mejor decisión.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.grisCalido),
          ),
          const SizedBox(height: 16),

          // Selector interactivo de estrellas
          Row(
            children: [
              Text(
                'Puntuación: ',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.carbon,
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(5, (i) {
                final starIndex = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStars = starIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      starIndex <= _selectedStars ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 30,
                      color: starIndex <= _selectedStars ? AppColors.champagne : AppColors.arena,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 12),
              if (_selectedStars > 0)
                Text(
                  ['', 'Muy malo', 'Malo', 'Regular', 'Bueno', 'Excelente'][_selectedStars],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.cobreOscuro,
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
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: const BorderSide(color: AppColors.arena),
              ),
              filled: true,
              fillColor: AppColors.blanco,
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blanco),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _isSubmittingRating
                    ? 'Publicando...'
                    : isUpdate
                        ? 'Actualizar Reseña'
                        : 'Publicar Reseña',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.carbon,
                foregroundColor: AppColors.blanco,
                minimumSize: const Size(double.infinity, 46),
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
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
        color: AppColors.marfil,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.arena),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.grisCalido),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Inicia sesión para calificar este producto y compartir tu opinión.',
              style: GoogleFonts.plusJakartaSans(color: AppColors.carbon, fontSize: 13.5),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: TextButton.styleFrom(foregroundColor: AppColors.cobreOscuro),
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
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cobreOscuro),
        ),
      );
    }
    if (_ratingsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(_ratingsError!, style: const TextStyle(color: AppColors.error)),
      );
    }
    if (_ratings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.rate_review_outlined, size: 44, color: AppColors.arena),
            const SizedBox(height: 12),
            Text(
              'Sé el primero en reseñar este producto',
              style: GoogleFonts.plusJakartaSans(color: AppColors.grisCalido, fontSize: 14),
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
        color: isOwn ? AppColors.marfil : AppColors.blanco,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: isOwn ? AppColors.champagne : AppColors.arena.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.marfil,
                child: Text(
                  rating.username[0].toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.carbon,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: AppColors.carbon,
                          ),
                        ),
                        if (isOwn) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.cobreOscuro.withValues(alpha: 0.1),
                              borderRadius: AppRadius.borderPill,
                            ),
                            child: Text(
                              'Tu reseña',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: AppColors.cobreOscuro,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatDate(rating.updatedAt ?? rating.createdAt),
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.grisCalido),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) => Icon(
                  i < rating.rating ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 16,
                  color: AppColors.champagne,
                )),
              ),
            ],
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              rating.comment!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: AppColors.carbon,
                height: 1.5,
              ),
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
