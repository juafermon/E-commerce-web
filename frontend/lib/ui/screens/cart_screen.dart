// lib/ui/screens/cart_screen.dart
// Esta pantalla muestra el contenido del carrito de compras del usuario. Permite revisar los artículos añadidos, modificar las cantidades, eliminar productos y proceder al checkout. Al confirmar la compra, se envía la información al backend para crear una orden en Supabase, y se maneja la respuesta para mostrar mensajes de éxito o error al usuario.
// Importamos las dependencias necesarias: Flutter Material para los widgets, CartProvider para manejar el estado del carrito, y OrderService para interactuar con el backend al momento de realizar la compra.

import 'package:flutter/material.dart';
import '../../data/services/cart_provider.dart';
import '../../data/services/order_service.dart';

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
      // Intentamos disparar la transacción en Supabase a través del Backend
      bool success = await _orderService.createOrder(widget.cartProvider.items, address);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Pedido realizado con éxito! 📦'), backgroundColor: Colors.green),
        );
        widget.cartProvider.clearCart(); // Vaciamos el carrito local
        _addressController.clear();
        Navigator.pop(context); // Regresa al catálogo
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
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
                      return ListTile(
                        leading: const Icon(Icons.shopping_bag_outlined, color: Colors.blue),
                        title: Text(item.article.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Cant: ${item.quantity} x \$${item.article.price.toStringAsFixed(0)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => setState(() => cart.removeArticle(item.article.id)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                              onPressed: () => setState(() => cart.addArticle(item.article)),
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