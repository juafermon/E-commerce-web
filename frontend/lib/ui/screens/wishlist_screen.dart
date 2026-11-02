// lib/ui/screens/wishlist_screen.dart
// Pantalla de Lista de Deseos adaptada al sistema visual Relaxbell:
// Fondo Marfil, tarjetas en Blanco con borde Arena, títulos en Playfair Display y botones en Carbón.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/wishlist_provider.dart';
import '../../data/services/cart_provider.dart';
import '../../data/services/catalog_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/article_model.dart';
import '../widgets/safe_network_image.dart';
import '../widgets/store_app_bar.dart';
import '../theme/app_colors.dart';

class WishlistScreen extends StatefulWidget {
  final WishlistProvider wishlistProvider;
  final CartProvider cartProvider;

  const WishlistScreen({
    super.key,
    required this.wishlistProvider,
    required this.cartProvider,
  });

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final AuthService _authService = AuthService();
  final CatalogService _catalogService = CatalogService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.wishlistProvider.loadWishlist();
    });
  }

  Future<void> _handleAddToCart(ArticleModel article) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final token = await _authService.getToken();
    if (token == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para añadir productos al carrito'),
          backgroundColor: AppColors.carbon,
        ),
      );
      navigator.pushNamed('/login');
      return;
    }

    try {
      final success = await widget.cartProvider.addArticleWithStockCheck(
        article,
        _catalogService,
      );
      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${article.name} añadido al carrito'),
            backgroundColor: AppColors.carbon,
            action: SnackBarAction(
              label: 'Ver Carrito',
              textColor: AppColors.blanco,
              onPressed: () => navigator.pushNamed('/cart'),
            ),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Sin stock disponible en este momento.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleRemoveFromWishlist(ArticleModel article) async {
    try {
      await widget.wishlistProvider.toggle(article);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${article.name} eliminado de tu lista de deseos'),
            backgroundColor: AppColors.carbon,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
          widget.wishlistProvider.loadWishlist();
        },
      ),
      body: AnimatedBuilder(
        animation: widget.wishlistProvider,
        builder: (context, _) {
          if (widget.wishlistProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.cobreOscuro),
                  SizedBox(height: 16),
                  Text(
                    'Cargando tu lista de deseos...',
                    style: TextStyle(color: AppColors.grisCalido),
                  ),
                ],
              ),
            );
          }

          if (widget.wishlistProvider.items.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildWishlistContent(isWeb);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.blanco,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.arena,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 46,
                color: AppColors.champagne,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            Text(
              'Tu lista de deseos está vacía',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.carbon,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Explora el catálogo y guarda tus productos\nfavoritos tocando el ícono ♥',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.grisCalido,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/catalog'),
              icon: const Icon(Icons.storefront_outlined, size: 18),
              label: Text(
                'Explorar Catálogo',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.carbon,
                foregroundColor: AppColors.blanco,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space6,
                  vertical: AppSpacing.space3 + 2,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMd,
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistContent(bool isWeb) {
    final items = widget.wishlistProvider.items;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? AppSpacing.space12 : AppSpacing.space4,
        vertical: AppSpacing.space6,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.cobreOscuro,
                    size: 26,
                  ),
                  const SizedBox(width: AppSpacing.space2 + 2),
                  Text(
                    'Mi Lista de Deseos',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.carbon,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.marfil,
                      borderRadius: AppRadius.borderPill,
                      border: Border.all(
                        color: AppColors.champagne.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Text(
                      '${items.length} ${items.length == 1 ? 'artículo' : 'artículos'}',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.carbon,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space6),

              // Grid o lista según el ancho
              isWeb
                  ? GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        mainAxisSpacing: AppSpacing.space4,
                        crossAxisSpacing: AppSpacing.space4,
                        childAspectRatio: 0.70,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _buildWishlistCard(items[index]),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space3),
                      itemBuilder: (context, index) =>
                          _buildWishlistListTile(items[index]),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta estilo grid (para web)
  Widget _buildWishlistCard(ArticleModel article) {
    final hasStock = article.stock > 0 && article.isAvailable;
    final imageUrl = article.imageUrls.isNotEmpty
        ? article.imageUrls.first
        : article.imageUrl;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/product-detail',
        arguments: article,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blanco,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: AppColors.arena.withValues(alpha: 0.7),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.carbon.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Container(
                    color: AppColors.marfil,
                    child: imageUrl != null
                        ? SafeNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.cobreOscuro,
                              ),
                            ),
                            errorWidget: const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.arena,
                              size: 32,
                            ),
                          )
                        : const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.arena,
                            size: 32,
                          ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.space2,
                  right: AppSpacing.space2,
                  child: _WishlistHeartButton(
                    article: article,
                    wishlistProvider: widget.wishlistProvider,
                    onRemoved: () => _handleRemoveFromWishlist(article),
                  ),
                ),
                if (article.hasDiscount)
                  Positioned(
                    top: AppSpacing.space2,
                    left: AppSpacing.space2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space2,
                        vertical: AppSpacing.space1,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.cobreOscuro,
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        '-${article.discountPercentage}%',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.blanco,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (!hasStock)
                  Positioned(
                    top: article.hasDiscount ? 34 : 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Agotado',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.error,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.category != null)
                    Text(
                      article.category!.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.grisCalido,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    article.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.carbon,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      if (article.hasDiscount)
                        Text(
                          ArticleModel.formatPrice(article.originalPrice!),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: AppColors.grisCalido,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        ArticleModel.formatPrice(article.price),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.carbon,
                        ),
                      ),
                      if (article.hasDiscount)
                        Text(
                          '(-${article.discountPercentage}%)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cobreOscuro,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          hasStock ? () => _handleAddToCart(article) : null,
                      icon: const Icon(Icons.add_shopping_cart, size: 15),
                      label: Text(
                        hasStock ? 'Añadir al Carrito' : 'Sin Stock',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasStock
                            ? AppColors.carbon
                            : AppColors.marfil,
                        foregroundColor:
                            hasStock ? AppColors.blanco : AppColors.grisCalido,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.borderMd,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta estilo lista (para móvil)
  Widget _buildWishlistListTile(ArticleModel article) {
    final hasStock = article.stock > 0 && article.isAvailable;
    final imageUrl = article.imageUrls.isNotEmpty
        ? article.imageUrls.first
        : article.imageUrl;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/product-detail',
        arguments: article,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blanco,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: AppColors.arena.withValues(alpha: 0.7),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.carbon.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Stack(
              children: [
                SizedBox(
                  width: 100,
                  height: 105,
                  child: Container(
                    color: AppColors.marfil,
                    child: imageUrl != null
                        ? SafeNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.cobreOscuro,
                              ),
                            ),
                            errorWidget: const Icon(Icons.image_not_supported_outlined, size: 28, color: AppColors.arena),
                          )
                        : const Icon(Icons.image_not_supported_outlined, size: 28, color: AppColors.arena),
                  ),
                ),
                if (article.hasDiscount)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.cobreOscuro,
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        '-${article.discountPercentage}%',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.blanco,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.carbon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        if (article.hasDiscount)
                          Text(
                            ArticleModel.formatPrice(article.originalPrice!),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.grisCalido,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          ArticleModel.formatPrice(article.price),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.carbon,
                          ),
                        ),
                        if (article.hasDiscount)
                          Text(
                            '(-${article.discountPercentage}%)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.cobreOscuro,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: hasStock
                                ? () => _handleAddToCart(article)
                                : null,
                            icon: const Icon(Icons.add_shopping_cart, size: 14),
                            label: Text(
                              hasStock ? 'Al Carrito' : 'Sin Stock',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: hasStock
                                  ? AppColors.carbon
                                  : AppColors.grisCalido,
                              side: BorderSide(
                                color: hasStock
                                    ? AppColors.carbon
                                    : AppColors.arena,
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.borderSm,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _handleRemoveFromWishlist(article),
                          icon: const Icon(
                            Icons.favorite_rounded,
                            color: AppColors.cobreOscuro,
                            size: 20,
                          ),
                          tooltip: 'Quitar de wishlist',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de corazón reutilizable en tarjetas de wishlist
class _WishlistHeartButton extends StatelessWidget {
  final ArticleModel article;
  final WishlistProvider wishlistProvider;
  final VoidCallback onRemoved;

  const _WishlistHeartButton({
    required this.article,
    required this.wishlistProvider,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blanco,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.arena.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.carbon.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onRemoved,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(7),
          child: Icon(
            Icons.favorite_rounded,
            color: AppColors.cobreOscuro,
            size: 18,
          ),
        ),
      ),
    );
  }
}
