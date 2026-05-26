// lib/ui/screens/catalog_screen.dart
import 'package:flutter/material.dart';
import '../../data/models/article_model.dart';
import '../../data/services/catalog_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/cart_provider.dart';

class CatalogScreen extends StatefulWidget {
  final CartProvider cartProvider;
  const CatalogScreen({Key? key, required this.cartProvider}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final CatalogService _catalogService = CatalogService();
  final AuthService _authService = AuthService();
  
  late Future<List<ArticleModel>> _futureArticles;
  String _selectedCategory = 'Todos'; // Estado para controlar el filtro lateral

  // Lista simulada de categorías (En el futuro puedes traerlas de Supabase)
  final List<String> _categories = [
    'Todos',
    'Electrónica',
    'Ropa y Calzado',
    'Hogar',
    'Deportes',
    'Accesorios'
  ];

  @override
  void initState() {
    super.initState();
    _futureArticles = _catalogService.fetchArticles();
  }

  void _handleNavigation(String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando a: $section (Próximamente disponible)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detectamos el ancho de la pantalla para hacer la barra lateral responsiva
    final bool isWeb = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: Colors.blue, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Mi Tienda Virtual', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)
            ),
            const SizedBox(width: 40),
            
            // BARRA SUPERIOR: Accesos rápidos en pantallas grandes (Web)
            if (isWeb) ...[
              TextButton.icon(
                onPressed: () => _handleNavigation('Descuentos'),
                icon: const Icon(Icons.local_offer_outlined, size: 18, color: Colors.orange),
                label: const Text('Descuentos', style: TextStyle(color: Colors.black87)),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () => _handleNavigation('Más Vendidos'),
                icon: const Icon(Icons.workspace_premium_outlined, size: 18, color: Colors.amber),
                label: const Text('Más Vendidos', style: TextStyle(color: Colors.black87)),
              ),
            ]
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black26,
        actions: [
          // Botón del Carrito con Badge
          IconButton(
            icon: Badge(
              label: Text(widget.cartProvider.itemCount.toString()),
              child: const Icon(Icons.shopping_cart, color: Colors.black87),
            ),
            tooltip: 'Ver Carrito',
            onPressed: () async {
              String? token = await _authService.getToken();
              if (token == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debes iniciar sesión para ver tu carrito')),
                );
                Navigator.pushNamed(context, '/login');
              } else {
                Navigator.pushNamed(context, '/cart').then((_) => setState(() {}));
              }
            },
          ),
          const SizedBox(width: 8),
          
          // BARRA SUPERIOR: Iniciar / Cerrar Sesión Dinámico
          FutureBuilder<String?>(
            future: _authService.getToken(),
            builder: (context, snapshot) {
              bool isLoggedIn = snapshot.hasData && snapshot.data != null;
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (isLoggedIn) {
                      await _authService.logout();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sesión cerrada')),
                      );
                    } else {
                      Navigator.pushNamed(context, '/login').then((_) => setState(() {}));
                    }
                  },
                  icon: Icon(isLoggedIn ? Icons.logout : Icons.login, size: 16),
                  label: Text(isLoggedIn ? 'Salir' : 'Iniciar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLoggedIn ? Colors.grey[200] : Colors.blue,
                    foregroundColor: isLoggedIn ? Colors.black87 : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      
      // CUERPO PRINCIPAL CON ESTRUCTURA DE DOS COLUMNAS
      body: Row(
        children: [
          // 1. BARRA LATERAL DE CATEGORÍAS (Solo visible en Web/Pantallas anchas)
          if (isWeb)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey[200]!)),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                children: [
                  const Text(
                    'Categorías',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  ..._categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        selected: isSelected,
                        selectedTileColor: Colors.blue[50],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        leading: Icon(
                          category == 'Todos' ? Icons.grid_view : Icons.label_outline,
                          color: isSelected ? Colors.blue : Colors.black54,
                        ),
                        title: Text(
                          category,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.blue : Colors.black87,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

          // 2. COLUMNA DEL CATÁLOGO DE PRODUCTOS
          Expanded(
            child: FutureBuilder<List<ArticleModel>>(
              future: _futureArticles,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay artículos disponibles.'));
                }

                // Filtrado lógico local según la categoría seleccionada
                final allArticles = snapshot.data!;
                final articles = _selectedCategory == 'Todos'
                    ? allArticles
                    : allArticles.where((a) => a.category == _selectedCategory).toList();

                if (articles.isEmpty) {
                  return Center(
                    child: Text('No hay productos en la categoría "$_selectedCategory".'),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return Card(
                        elevation: 2,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: article.imageUrl != null
                                    ? Image.network(article.imageUrl!, fit: BoxFit.cover)
                                    : const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    article.category ?? 'Sin categoría',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '\$${article.price.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                      Text(
                                        'Stock: ${article.stock}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      String? token = await _authService.getToken();
                                      if (token == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Inicia sesión para añadir productos'), backgroundColor: Colors.orange),
                                        );
                                        Navigator.pushNamed(context, '/login');
                                      } else {
                                        setState(() {
                                          widget.cartProvider.addArticle(article);
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${article.name} añadido'), duration: const Duration(seconds: 1)),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.add_shopping_cart, size: 14),
                                    label: const Text('Añadir', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 34),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}