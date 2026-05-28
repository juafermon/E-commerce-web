// lib/ui/widgets/category_sidebar.dart 
// Widget de barra lateral para mostrar categorías
import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';
import '../../data/services/category_service.dart';

class CategorySidebar extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySidebar({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CategorySidebar> createState() => _CategorySidebarState();
}

class _CategorySidebarState extends State<CategorySidebar> {
  final CategoryService _categoryService = CategoryService();
  late Future<List<CategoryModel>> _futureCategories;

  @override
  void initState() {
    super.initState();
    _futureCategories = _categoryService.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: FutureBuilder<List<CategoryModel>>(
        future: _futureCategories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Error al cargar categorías', style: TextStyle(color: Colors.red)),
            );
          }

          // Creamos la lista de strings para la UI, insertando 'Todos' al principio
          final apiCategories = snapshot.data ?? [];
          final List<String> displayCategories = ['Todos', ...apiCategories.map((c) => c.name)];

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            children: [
              const Text(
                'Categorías',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ...displayCategories.map((category) {
                final isSelected = widget.selectedCategory == category;
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
                    onTap: () => widget.onCategorySelected(category),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}