// lib/ui/screens/wishlist_screen.dart
// Pantalla dedicada para la Lista de Deseos del usuario.
// Muestra todos los artículos guardados con acciones rápidas: ver detalle, agregar al carrito y quitar de la wishlist.

import 'package:flutter/material.dart';
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
    // Refresca la wishlist al abrir la pantalla
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
          backgroundColor: Colors.orange,
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
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ver Carrito',
              textColor: Colors.white,
              onPressed: () => navigator.pushNamed('/cart'),
            ),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Sin stock disponible en este momento.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
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
            backgroundColor: Colors.grey[700],
            action: SnackBarAction(
              label: 'Deshacer',
              textColor: Colors.white,
              onPressed: () async {
                await widget.wishlistProvider.toggle(article);
              },
            ),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FF),
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
                  CircularProgressIndicator(color: Color(0xFFBE185D)),
                  SizedBox(height: 16),
                  Text(
                    'Cargando tu lista de deseos...',
                    style: TextStyle(color: Colors.grey),
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
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF9A8D4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 56,
                color: Color(0xFFBE185D),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Tu lista de deseos está vacía',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E1065),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Explora el catálogo y guarda tus productos\nfavoritos tocando el ícono ♥',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/catalog'),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text(
                'Explorar Catálogo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBE185D),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
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
        horizontal: isWeb ? 48 : 16,
        vertical: 24,
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
                    color: Color(0xFFBE185D),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Mi Lista de Deseos',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E1065),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBE185D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${items.length} ${items.length == 1 ? 'artículo' : 'artículos'}',
                      style: const TextStyle(
                        color: Color(0xFFBE185D),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Grid o lista según el ancho
              isWeb
                  ? GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 320,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _buildWishlistCard(items[index]),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con botón de quitar wishlist
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: imageUrl != null
                        ? SafeNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: Container(
                              color: Colors.grey[100],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[100],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _WishlistHeartButton(
                    article: article,
                    wishlistProvider: widget.wishlistProvider,
                    onRemoved: () => _handleRemoveFromWishlist(article),
                  ),
                ),
                if (article.hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.discountBadge,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${article.discountPercentage}%',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          color: Colors.white,
                          fontSize: 11,
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
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Agotado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.category != null)
                    Text(
                      article.category!,
                      style: const TextStyle(
                        color: Color(0xFFBE185D),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    article.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      if (article.hasDiscount)
                        Text(
                          ArticleModel.formatPrice(article.originalPrice!),
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: AppColors.neutral400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        ArticleModel.formatPrice(article.price),
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutral900,
                        ),
                      ),
                      if (article.hasDiscount)
                        Text(
                          '(-${article.discountPercentage}%)',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.discountBadge,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          hasStock ? () => _handleAddToCart(article) : null,
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: Text(
                        hasStock ? 'Añadir al Carrito' : 'Sin Stock',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasStock
                            ? const Color(0xFF2563EB)
                            : Colors.grey[300],
                        foregroundColor:
                            hasStock ? Colors.white : Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Imagen con Badge de Descuento
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(14)),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: imageUrl != null
                        ? SafeNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: Container(
                              color: Colors.grey[100],
                              child:
                                  const Icon(Icons.image_not_supported, size: 32),
                            ),
                          )
                        : Container(
                            color: Colors.grey[100],
                            child:
                                const Icon(Icons.image_not_supported, size: 32),
                          ),
                  ),
                ),
                if (article.hasDiscount)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.discountBadge,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-${article.discountPercentage}%',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              color: AppColors.neutral400,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          ArticleModel.formatPrice(article.price),
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                          ),
                        ),
                        if (article.hasDiscount)
                          Text(
                            '(-${article.discountPercentage}%)',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.discountBadge,
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
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: hasStock
                                  ? const Color(0xFF2563EB)
                                  : Colors.grey,
                              side: BorderSide(
                                color: hasStock
                                    ? const Color(0xFF2563EB)
                                    : Colors.grey[300]!,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _handleRemoveFromWishlist(article),
                          icon: const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFBE185D),
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

/// Botón de corazón animado reutilizable dentro de la pantalla de wishlist
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
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onRemoved,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedBuilder(
            animation: wishlistProvider,
            builder: (context, _) {
              return const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFBE185D),
                size: 20,
              );
            },
          ),
        ),
      ),
    );
  }
}
