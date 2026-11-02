// lib/ui/screens/cart_screen.dart
// Pantalla de Carrito de Compras estilizada con el sistema de diseño Relaxbell:
// Marfil de fondo, tarjetas en Blanco con bordes Arena, títulos en Playfair Display y botones en Carbón.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/cart_provider.dart';
import '../../data/services/order_service.dart';
import '../../data/services/catalog_service.dart';
import '../../data/models/article_model.dart';
import '../theme/app_colors.dart';

class CartScreen extends StatefulWidget {
  final CartProvider cartProvider;

  const CartScreen({super.key, required this.cartProvider});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final OrderService _orderService = OrderService();
  final TextEditingController _addressController = TextEditingController();
  bool _isProcessing = false;

  void _checkout() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa una dirección de envío'),
          backgroundColor: AppColors.carbon,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      bool success = await _orderService.createOrder(widget.cartProvider.items, address);

      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('¡Pedido realizado con éxito! 📦'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.cartProvider.clearCart();
        _addressController.clear();
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cartProvider;

    return Scaffold(
      backgroundColor: AppColors.marfil,
      appBar: AppBar(
        title: Text(
          'Mi Carrito',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppColors.carbon,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.blanco,
        foregroundColor: AppColors.carbon,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: AppColors.arena.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.blanco,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.arena),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 42,
                        color: AppColors.champagne,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      'Tu carrito está vacío',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.carbon,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'Explora nuestro catálogo para añadir productos a tu orden.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: AppColors.grisCalido,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space6),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Volver a la Tienda'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.carbon,
                        foregroundColor: AppColors.blanco,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space6,
                          vertical: AppSpacing.space3,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.borderMd,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      final TextEditingController quantityController = 
                          TextEditingController(text: item.quantity.toString());

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.space3),
                        decoration: BoxDecoration(
                          color: AppColors.blanco,
                          borderRadius: AppRadius.borderMd,
                          border: Border.all(
                            color: AppColors.arena.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.space3),
                          child: Row(
                            children: [
                              // Ícono o Miniatura
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.marfil,
                                  borderRadius: AppRadius.borderSm,
                                  border: Border.all(color: AppColors.arena.withValues(alpha: 0.5)),
                                ),
                                child: const Icon(
                                  Icons.spa_outlined,
                                  color: AppColors.cobreOscuro,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.space3),

                              // Título y Precio unitario
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.article.name,
                                      style: GoogleFonts.playfairDisplay(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.carbon,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${ArticleModel.formatPrice(item.article.price)} c/u',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.grisCalido,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Controles de Cantidad
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                                    color: AppColors.carbon,
                                    onPressed: () {
                                      if (item.quantity > 1) {
                                        setState(() {
                                          cart.removeArticle(item.article.id);
                                          quantityController.text = item.quantity.toString();
                                        });
                                      }
                                    },
                                  ),
                                  SizedBox(
                                    width: 36,
                                    height: 30,
                                    child: TextFormField(
                                      controller: quantityController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.carbon,
                                      ),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        fillColor: AppColors.marfil,
                                        filled: true,
                                        border: OutlineInputBorder(
                                          borderRadius: AppRadius.borderSm,
                                          borderSide: const BorderSide(color: AppColors.arena),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderRadius: AppRadius.borderSm,
                                          borderSide: BorderSide(color: AppColors.cobreOscuro, width: 1.5),
                                        ),
                                      ),
                                      onFieldSubmitted: (value) {
                                        final int? newQty = int.tryParse(value);

                                        if (newQty == null || newQty < 1) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('La cantidad mínima es 1'),
                                              backgroundColor: AppColors.carbon,
                                            ),
                                          );
                                          setState(() {
                                            quantityController.text = item.quantity.toString();
                                          });
                                          return;
                                        }

                                        if (newQty > item.article.stock) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Stock máximo disponible: ${item.article.stock}'),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                          setState(() {
                                            quantityController.text = item.quantity.toString();
                                          });
                                          return;
                                        }

                                        cart.setItemQuantity(item.article.id, newQty);
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                    color: AppColors.carbon,
                                    onPressed: () async {
                                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                                      try {
                                        bool success = await cart.addArticleWithStockCheck(
                                          item.article,
                                          CatalogService(),
                                        );
                                        if (success) {
                                          setState(() {
                                            quantityController.text = item.quantity.toString();
                                          });
                                        } else {
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(
                                              content: Text('No hay más stock disponible para ${item.article.name}'),
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
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    color: AppColors.grisCalido,
                                    tooltip: 'Eliminar producto',
                                    onPressed: () {
                                      cart.removeItem(item.article.id);
                                      setState(() {});
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${item.article.name} eliminado'),
                                          backgroundColor: AppColors.carbon,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Formulario de envío y Totales
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space6),
                  decoration: BoxDecoration(
                    color: AppColors.blanco,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg),
                    ),
                    border: Border.all(
                      color: AppColors.arena.withValues(alpha: 0.7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.carbon.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Dirección de Entrega',
                          prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.cobreOscuro),
                          filled: true,
                          fillColor: AppColors.marfil,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.borderMd,
                            borderSide: const BorderSide(color: AppColors.arena),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total a Pagar:',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.carbon,
                            ),
                          ),
                          Text(
                            ArticleModel.formatPrice(cart.totalAmount),
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.cobreOscuro,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      ElevatedButton(
                        onPressed: _isProcessing ? null : _checkout,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.carbon,
                          foregroundColor: AppColors.blanco,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.borderMd,
                          ),
                          elevation: 0,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: AppColors.blanco,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Confirmar Compra',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}