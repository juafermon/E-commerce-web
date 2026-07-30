// lib/ui/screens/cart_screen.dart
// Esta pantalla muestra el contenido del carrito de compras del usuario. Permite revisar los artículos añadidos, modificar las cantidades, eliminar productos y proceder al checkout. Al confirmar la compra, se envía la información al backend para crear una orden en Supabase, y se maneja la respuesta para mostrar mensajes de éxito o error al usuario.
// Importamos las dependencias necesarias: Flutter Material para los widgets, CartProvider para manejar el estado del carrito, y OrderService para interactuar con el backend al momento de realizar la compra.

import 'package:flutter/material.dart';
import '../../data/services/cart_provider.dart';
import '../../data/services/order_service.dart';
import '../../data/services/catalog_service.dart';

class CartScreen extends StatefulWidget {
  final CartProvider cartProvider; // Recibe el estado global del carrito

  const CartScreen({Key? key, required this.cartProvider}) : super(key: key);

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
        const SnackBar(content: Text('Por favor, ingresa una dirección de envío')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      // Intentamos disparar la transacción en Supabase a través del Backend
      bool success = await _orderService.createOrder(widget.cartProvider.items, address);

      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('¡Pedido realizado con éxito! 📦'), backgroundColor: Colors.green),
        );
        widget.cartProvider.clearCart(); // Vaciamos el carrito local
        _addressController.clear();
        navigator.pop(); // Regresa al catálogo
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
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
      appBar: AppBar(
        title: const Text('Mi Carrito de Compras'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Tu carrito está vacío.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      
                      // Controlador local para el campo de texto numérico de esta fila
                      final TextEditingController quantityController = 
                          TextEditingController(text: item.quantity.toString());

                      return ListTile(
                        leading: const Icon(Icons.shopping_bag_outlined, color: Colors.blue),
                        title: Text(item.article.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('\$${item.article.price.toStringAsFixed(0)} c/u'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Botón de decrementar (-)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  setState(() {
                                    cart.removeArticle(item.article.id);
                                    quantityController.text = item.quantity.toString();
                                  });
                                }
                              },
                            ),

                            // 2. Campo de cantidad manual editable
                            SizedBox(
                              width: 45,
                              height: 32,
                              child: TextFormField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                                  ),
                                ),
                                onFieldSubmitted: (value) {
                                  final int? newQty = int.tryParse(value);

                                  if (newQty == null || newQty < 1) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('La cantidad mínima es 1')),
                                    );
                                    setState(() {
                                      quantityController.text = item.quantity.toString();
                                    });
                                    return;
                                  }

                                  if (newQty > item.article.stock) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Stock máximo disponible: ${item.article.stock}')),
                                    );
                                    setState(() {
                                      quantityController.text = item.quantity.toString();
                                    });
                                    return;
                                  }

                                  // Si pasa las validaciones, asignamos la cantidad manual directamente
                                  setState(() {
                                    item.quantity = newQty;
                                    cart.notifyListeners(); // Actualiza el total de la pantalla
                                  });
                                },
                              ),
                            ),

                            // 3. Botón de incrementar (+)
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
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
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Error de conexión o red: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                            
                            const SizedBox(width: 4),
                            const VerticalDivider(width: 1, indent: 10, endIndent: 10),
                            
                            // 4. Botón para remover por completo del carrito
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  // Remueve de raíz el artículo usando el id
                                  cart.items.removeWhere((i) => i.article.id == item.article.id);
                                  cart.notifyListeners();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${item.article.name} eliminado')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Formulario de envío y Totales
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Dirección de Entrega',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          filled: true,
                          fillColor: Colors.white,          
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total a Pagar:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('\$${cart.totalAmount.toStringAsFixed(0)}', 
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isProcessing ? null : _checkout,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isProcessing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Confirmar Compra', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}