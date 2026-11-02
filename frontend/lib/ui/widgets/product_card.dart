// lib/ui/widgets/product_card.dart
// Tarjeta de producto estilizada con la paleta de lujo Relaxbell:
// Superficie Blanco, Borde Arena, Títulos en Playfair Display, Botones en Carbón y Acentos Cobre Oscuro.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'safe_network_image.dart';
import '../../data/models/article_model.dart';
import '../../data/services/cart_provider.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/catalog_service.dart';
import '../theme/app_colors.dart';

class ProductCard extends StatefulWidget {
  final ArticleModel article;
  final CartProvider cartProvider;
  final AuthService authService;
  final VoidCallback onArticleAdded;

  const ProductCard({
    super.key,
    required this.article,
    required this.cartProvider,
    required this.authService,
    required this.onArticleAdded,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isLoading = false;
  bool _isHovered = false;

  void _navigateToDetail() {
    Navigator.pushNamed(
      context,
      '/product-detail',
      arguments: widget.article,
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final hasDiscount = article.hasDiscount;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppTransitions.duration,
        curve: AppTransitions.curve,
        decoration: BoxDecoration(
          color: AppColors.blanco,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: _isHovered
                ? AppColors.champagne.withValues(alpha: 0.8)
                : AppColors.arena.withValues(alpha: 0.7),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.carbon.withValues(alpha: _isHovered ? 0.08 : 0.02),
              blurRadius: _isHovered ? 12 : 4,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _navigateToDetail,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del Producto con Badge de Descuento
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.marfil,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppRadius.md),
                        ),
                      ),
                      child: article.imageUrl != null
                          ? SafeNetworkImage(
                              imageUrl: article.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.cobreOscuro,
                                  ),
                                ),
                              ),
                              errorWidget: const Icon(
                                Icons.image_not_supported_outlined,
                                size: 36,
                                color: AppColors.arena,
                              ),
                            )
                          : const Icon(
                              Icons.image_not_supported_outlined,
                              size: 36,
                              color: AppColors.arena,
                            ),
                    ),
                    if (hasDiscount)
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
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Detalles del Producto
              Padding(
                padding: const EdgeInsets.all(AppSpacing.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoría
                    Text(
                      (article.category ?? 'General').toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.grisCalido,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.space1),

                    // Nombre en Playfair Display
                    Text(
                      article.name,
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: AppColors.carbon,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.space1),

                    // Reseñas y Estrellas en Champagne
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: article.ratingCount > 0
                              ? AppColors.champagne
                              : AppColors.arena,
                        ),
                        const SizedBox(width: AppSpacing.space1),
                        Text(
                          article.ratingCount > 0
                              ? '${article.ratingAvg.toStringAsFixed(1)} (${article.ratingCount})'
                              : 'Nuevo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.grisCalido,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space2),

                    // Precios y Stock
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpacing.space1 + 1,
                            runSpacing: 2,
                            children: [
                              if (hasDiscount) ...[
                                Text(
                                  ArticleModel.formatPrice(article.originalPrice!),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: AppColors.grisCalido,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: AppColors.grisCalido,
                                  ),
                                ),
                              ],
                              Text(
                                ArticleModel.formatPrice(article.price),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.carbon,
                                ),
                              ),
                              if (hasDiscount)
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
                        ),
                        Text(
                          'Stock: ${article.stock}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: AppColors.grisCalido,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space3),

                    // Botón "Añadir" en Carbón
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);
                              String? token = await widget.authService.getToken();
                              if (token == null) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Inicia sesión para añadir productos'),
                                    backgroundColor: AppColors.carbon,
                                  ),
                                );
                                navigator.pushNamed('/login');
                              } else {
                                setState(() {
                                  _isLoading = true;
                                });
                                try {
                                  bool success = await widget.cartProvider.addArticleWithStockCheck(
                                    widget.article,
                                    CatalogService(),
                                  );
                                  if (success) {
                                    widget.onArticleAdded();
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('${widget.article.name} añadido al carrito'),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: AppColors.carbon,
                                      ),
                                    );
                                  } else {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('No hay más stock disponible para ${widget.article.name}'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Error de conexión: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              }
                            },
                      icon: _isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.blanco,
                              ),
                            )
                          : const Icon(Icons.add_shopping_cart, size: 14),
                      label: Text(
                        _isLoading ? 'Verificando...' : 'Añadir',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 34),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.borderMd,
                        ),
                        backgroundColor: AppColors.carbon,
                        foregroundColor: AppColors.blanco,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}