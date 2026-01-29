import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../models/category_model.dart';
import '../../models/professional_model.dart';
import '../../providers/data_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/professional/professional_card.dart';
import 'professional_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryScreen({
    super.key,
    required this. category,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _searchController = TextEditingController();
  String _sortBy = 'rating';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfessionals() async {
    final dataProvider = context.read<DataProvider>();
    await dataProvider.loadProfessionalsByCategory(widget.category.id);
  }

  void _navigateToDetail(ProfessionalModel professional) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfessionalDetailScreen(professional: professional),
      ),
    );
  }

  List<ProfessionalModel> _filterAndSort(List<ProfessionalModel> professionals) {
    final filtered = professionals.where((p) {
      if (_searchController.text.isEmpty) return true;
      final query = _searchController.text. toLowerCase();
      return p.displayName.toLowerCase().contains(query) ||
          p.profession.toLowerCase().contains(query) ||
          p.services.any((s) => s.toLowerCase().contains(query));
    }).toList();

    switch (_sortBy) {
      case 'rating': 
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'experience':
        filtered.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
        break;
      case 'reviews':
        filtered.sort((a, b) => b.totalReviews.compareTo(a.totalReviews));
        break;
      case 'verified':
        filtered.sort((a, b) {
          if (a.isVerified && !b.isVerified) return -1;
          if (!a.isVerified && b.isVerified) return 1;
          return 0;
        });
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor:  AppColors.background,
        leading: IconButton(
          icon:  const Icon(Iconsax. arrow_left, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.category.name, style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Iconsax.filter_tick : Iconsax.filter,
              color: _showFilters ? AppColors.primary : AppColors.white,
            ),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding:  const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors. surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.category.name. toLowerCase()}...',
                  hintStyle: TextStyle(color:  AppColors.textMuted),
                  prefixIcon: Icon(Iconsax.search_normal, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ?  IconButton(
                          icon:  Icon(Iconsax.close_circle, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Filter/Sort Options
          if (_showFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical:  8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort by',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize:  12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSortChip('rating', 'Rating', Iconsax.star1),
                        const SizedBox(width: 8),
                        _buildSortChip('experience', 'Experience', Iconsax.briefcase),
                        const SizedBox(width: 8),
                        _buildSortChip('reviews', 'Reviews', Iconsax.message),
                        const SizedBox(width: 8),
                        _buildSortChip('verified', 'Verified', Iconsax. verify),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: AppColors. surfaceLight),
                ],
              ),
            ),

          // Professionals List
          Expanded(
            child: Consumer<DataProvider>(
              builder: (context, dataProvider, _) {
                if (dataProvider.professionalsLoading) {
                  return const LoadingWidget();
                }

                final professionals = _filterAndSort(dataProvider.professionals);

                if (professionals.isEmpty) {
                  return EmptyState(
                    icon:  Iconsax.search_status,
                    title: 'No professionals found',
                    subtitle: _searchController.text.isNotEmpty
                        ? 'Try adjusting your search'
                        : 'No ${widget. category.name.toLowerCase()} available in your area',
                    buttonText: _searchController.text. isNotEmpty ?  'Clear Search' : null,
                    onButtonPressed: _searchController.text.isNotEmpty
                        ? () {
                            _searchController.clear();
                            setState(() {});
                          }
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadProfessionals,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: professionals.length,
                    itemBuilder: (context, index) {
                      final professional = professionals[index];
                      // FIXED: Use FutureBuilder for async check
                      return FutureBuilder<bool>(
                        future: dataProvider.isProfessionalUnlocked(professional.id),
                        initialData: false,
                        builder: (context, snapshot) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ProfessionalCard(
                              professional: professional,
                              onTap: () => _navigateToDetail(professional),
                              isUnlocked: snapshot.data ?? false,
                            ),
                          );
                        }
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

  Widget _buildSortChip(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;

    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ?  AppColors.primary : AppColors. surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors. primary : AppColors.surfaceLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:  isSelected ? AppColors.white :  AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}