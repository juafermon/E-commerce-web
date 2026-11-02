// lib/ui/widgets/category_sidebar.dart 
// Barra lateral de categorías con estética refinada Relaxbell:
// Playfair Display para encabezado, acentos en Cobre Oscuro y Champagne, fondo Blanco y bordes Arena.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/category_model.dart';
import '../../data/services/category_service.dart';
import '../theme/app_colors.dart';

class CategorySidebar extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySidebar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

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
      width: 250,
      decoration: BoxDecoration(
        color: AppColors.blanco,
        border: Border(
          right: BorderSide(
            color: AppColors.arena.withValues(alpha: 0.7),
            width: 1.0,
          ),
        ),
      ),
      child: FutureBuilder<List<CategoryModel>>(
        future: _futureCategories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.cobreOscuro,
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Text(
                'Error al cargar categorías',
                style: GoogleFonts.plusJakartaSans(color: AppColors.error),
              ),
            );
          }

          final apiCategories = snapshot.data ?? [];
          final List<String> displayCategories = ['Todos', ...apiCategories.map((c) => c.name)];

          return ListView(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.space6,
              horizontal: AppSpacing.space4,
            ),
            children: [
              Text(
                'Colecciones',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.carbon,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                'Explora por categoría',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: AppColors.grisCalido,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              ...displayCategories.map((category) {
                final isSelected = widget.selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: AppRadius.borderMd,
                      onTap: () => widget.onCategorySelected(category),
                      child: AnimatedContainer(
                        duration: AppTransitions.duration,
                        curve: AppTransitions.curve,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space3,
                          vertical: AppSpacing.space2 + 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.marfil : Colors.transparent,
                          borderRadius: AppRadius.borderMd,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.champagne.withValues(alpha: 0.8)
                                : Colors.transparent,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              category == 'Todos'
                                  ? Icons.grid_view_rounded
                                  : Icons.label_outline_rounded,
                              size: 17,
                              color: isSelected ? AppColors.cobreOscuro : AppColors.grisCalido,
                            ),
                            const SizedBox(width: AppSpacing.space3),
                            Expanded(
                              child: Text(
                                category,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.carbon : AppColors.carbon,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AppColors.cobreOscuro,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}