import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../models/category_model.dart';

class CategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final Function(CategoryModel) onCategoryTap;
  final bool showAsShops;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    this.showAsShops = false,
  });

  @override
  Widget build(BuildContext context) {
    // If no categories are loaded yet, show the default ones (Electrician, Plumber, etc.)
    if (categories.isEmpty) {
      return _buildDefaultCategories();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16, // Increased spacing for better layout
        childAspectRatio: 0.8, // Taller aspect ratio to fit text better
      ),
      itemCount: categories.length.clamp(0, 8),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(
          category: category,
          onTap: () => onCategoryTap(category),
        );
      },
    );
  }

  Widget _buildDefaultCategories() {
    final defaultCategories = [
      _DefaultCategory('Electrician', Icons.electrical_services, const Color(0xFFFFB800)),
      _DefaultCategory('Plumber', Icons.plumbing, const Color(0xFF3B82F6)),
      _DefaultCategory('Carpenter', Icons.handyman, const Color(0xFF8D6E63)),
      _DefaultCategory('Painter', Icons.format_paint, const Color(0xFFE91E63)),
      _DefaultCategory('Mechanic', Icons.car_repair, const Color(0xFFF44336)),
      _DefaultCategory('Cleaning', Icons.cleaning_services, const Color(0xFF00BCD4)),
      _DefaultCategory('Tutor', Icons.school, const Color(0xFF4CAF50)),
      _DefaultCategory('Beauty', Icons.face_retouching_natural, const Color(0xFFE040FB)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: defaultCategories.length,
      itemBuilder: (context, index) {
        final cat = defaultCategories[index];
        return _DefaultCategoryCard(
          name: cat.name,
          icon: cat.icon,
          color: cat.color,
          onTap: () {
            final category = CategoryModel(
              id: index.toString(),
              name: cat.name,
              slug: cat.name.toLowerCase(),
              iconName: cat.name.toLowerCase(),
            );
            onCategoryTap(category);
          },
        );
      },
    );
  }
}

class _DefaultCategory {
  final String name;
  final IconData icon;
  final Color color;

  _DefaultCategory(this.name, this.icon, this.color);
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Smart mapping: Determine icon and color based on category name/iconName
    final iconData = _getSmartIcon(category.iconName, category.name);
    final colorData = _getSmartColor(category.iconName, category.name);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 56, // Slightly larger touch target
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceNavy,
              borderRadius: BorderRadius.circular(18), // Softer corners
              border: Border.all(
                color: AppColors.borderNavy,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center( // Ensure icon is perfectly centered
              child: Icon(
                iconData,
                color: colorData,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              category.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to find the best icon based on name keywords
  IconData _getSmartIcon(String? iconName, String name) {
    final term = (iconName ?? name).toLowerCase();

    // Construction & Home
    if (term.contains('electric')) return Icons.electrical_services;
    if (term.contains('plumb')) return Icons.plumbing;
    if (term.contains('carpenter') || term.contains('wood')) return Icons.handyman;
    if (term.contains('paint')) return Icons.format_paint;
    if (term.contains('clean') || term.contains('maid')) return Icons.cleaning_services;
    if (term.contains('pest') || term.contains('bug')) return Icons.bug_report;
    if (term.contains('garden') || term.contains('lawn')) return Icons.grass;
    
    // Automotive
    if (term.contains('mechanic') || term.contains('car') || term.contains('auto')) return Icons.car_repair;
    if (term.contains('bike')) return Icons.two_wheeler;
    
    // Professional Services
    if (term.contains('legal') || term.contains('law')) return Icons.gavel;
    if (term.contains('medical') || term.contains('doctor') || term.contains('health')) return Icons.medical_services;
    if (term.contains('tech') || term.contains('computer') || term.contains('it')) return Icons.computer;
    if (term.contains('photo') || term.contains('camera')) return Icons.camera_alt;
    if (term.contains('event') || term.contains('party') || term.contains('wedding')) return Icons.celebration;
    if (term.contains('cater') || term.contains('food') || term.contains('cook')) return Icons.restaurant;
    
    // Education & Beauty
    if (term.contains('tutor') || term.contains('teach') || term.contains('school')) return Icons.school;
    if (term.contains('beauty') || term.contains('salon') || term.contains('hair')) return Icons.face_retouching_natural;
    if (term.contains('makeup')) return Icons.brush;

    // Default fallback
    return Iconsax.category; 
  }

  // Helper to find the best color based on name keywords
  Color _getSmartColor(String? iconName, String name) {
    final term = (iconName ?? name).toLowerCase();

    // Yellows/Oranges
    if (term.contains('electric')) return const Color(0xFFFFB800);
    if (term.contains('pest')) return const Color(0xFFFF9800);
    if (term.contains('cater') || term.contains('food')) return const Color(0xFFFF5722);

    // Blues
    if (term.contains('plumb')) return const Color(0xFF3B82F6);
    if (term.contains('clean')) return const Color(0xFF00BCD4);
    if (term.contains('tech') || term.contains('it')) return const Color(0xFF2196F3);
    if (term.contains('photo')) return const Color(0xFF03A9F4);

    // Reds/Pinks
    if (term.contains('paint')) return const Color(0xFFE91E63);
    if (term.contains('beauty') || term.contains('salon')) return const Color(0xFFE040FB);
    if (term.contains('mechanic') || term.contains('car')) return const Color(0xFFF44336);
    if (term.contains('medical')) return const Color(0xFFEF5350);

    // Greens
    if (term.contains('tutor') || term.contains('school')) return const Color(0xFF4CAF50);
    if (term.contains('garden')) return const Color(0xFF8BC34A);

    // Purples/Others
    if (term.contains('event')) return const Color(0xFF9C27B0);
    if (term.contains('legal')) return const Color(0xFFD4AF37); // Gold
    if (term.contains('carpenter')) return const Color(0xFF8D6E63); // Brown

    // Default fallback
    return AppColors.primary;
  }
}

class _DefaultCategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DefaultCategoryCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceNavy,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.borderNavy,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: color, size: 26),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}