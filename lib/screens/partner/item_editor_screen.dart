import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../models/item_model.dart';
import '../../providers/data_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class ItemEditorScreen extends StatefulWidget {
  final String shopId;
  final ItemModel? item;
  final String? initialType;

  const ItemEditorScreen({
    super.key,
    required this.shopId,
    this.item,
    this.initialType,
  });

  @override
  State<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends State<ItemEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _priceUnitController = TextEditingController();
  final _durationController = TextEditingController();
  final _tagController = TextEditingController();

  String _selectedType = 'service';
  List<String> _tags = [];
  bool _isActive = true;
  bool _isFeatured = false;
  bool _isLoading = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.item != null;

  final List<Map<String, dynamic>> _listingTypes = [
  {
    'value': 'service',
    'label': 'Service',
    'icon': Iconsax.briefcase,
    'color': AppColors.primary,
    'hint': 'e.g., AC Repair, House Cleaning',
    'priceHint': 'per service',
  },
  {
    'value': 'product',
    'label': 'Product',
    'icon': Iconsax.box,
    'color': AppColors.success,
    'hint': 'e.g., Electronics, Furniture',
    'priceHint': 'per item',
  },
  {
    'value': 'rental',
    'label': 'Rental',
    'icon': Iconsax.calendar,
    'color': AppColors.info,
    'hint': 'e.g., Camera, Equipment, Cars',
    'priceHint': 'per day/hour',
  },
  {
    'value': 'booking',
    'label': 'Booking',
    'icon': Iconsax.clock,
    'color': AppColors.warning,
    'hint': 'e.g., Hotels, Rooms, Appointments',
    'priceHint': 'per night/session',
  },
  {
    'value': 'other',
    'label': 'Other',
    'icon': Iconsax.more,
    'color': AppColors.accent,
    'hint': 'e.g., Real Estate, Custom listings',
    'priceHint': 'custom',
  },
];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.item != null) {
      final item = widget.item!;
      _nameController.text = item.name;
      _descriptionController.text = item.description ?? '';
      _priceController.text = item.price?.toString() ?? '';
      _priceUnitController.text = item.priceUnit ?? '';
      _durationController.text = item.durationMinutes?.toString() ?? '';
      _selectedType = item.priceType ?? 'service';
      _tags = List.from(item.tags);
      _isActive = item.isActive;
      _isFeatured = item.isFeatured;
    } else if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _priceUnitController.dispose();
    _durationController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Map<String, dynamic> get _currentType {
    return _listingTypes.firstWhere(
      (t) => t['value'] == _selectedType,
      orElse: () => _listingTypes[0],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dataProvider = context.read<DataProvider>();

    final itemData = {
      'shop_id': widget.shopId,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      'price': _priceController.text.isNotEmpty
          ? double.tryParse(_priceController.text)
          : null,
      'price_unit': _priceUnitController.text.trim().isNotEmpty
          ? _priceUnitController.text.trim()
          : null,
      'price_type': _selectedType,
      'duration_minutes': _durationController.text.isNotEmpty
          ? int.tryParse(_durationController.text)
          : null,
      'tags': _tags,
      'is_active': _isActive,
      'is_featured': _isFeatured,
    };

    bool success;
    if (_isEditing) {
      success = await dataProvider.updateItemWithTags(widget.item!.id, itemData);
    } else {
      final professional = dataProvider.selectedProfessional;
      if (professional == null) {
        setState(() => _isLoading = false);
        _showError('Professional profile not found');
        return;
      }
      final newItem = await dataProvider.createItemWithTags(professional.id, itemData);
      success = newItem != null;
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Listing updated!' : 'Listing added!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      _showError('Failed to save listing');
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Listing?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    final dataProvider = context.read<DataProvider>();
    final success = await dataProvider.deleteItem(widget.item!.id);

    if (!mounted) return;

    setState(() => _isDeleting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing deleted'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      _showError('Failed to delete listing');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _currentType['color'] as Color;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Listing' : 'Add Listing',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Iconsax.trash, color: AppColors.error),
              onPressed: _isDeleting ? null : _handleDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Listing Type Selector
              _buildSectionTitle('Listing Type'),
              const SizedBox(height: 12),
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // Basic Info
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),
              _buildBasicInfoCard(),
              const SizedBox(height: 24),

              // Pricing
              _buildSectionTitle('Pricing'),
              const SizedBox(height: 12),
              _buildPricingCard(),
              const SizedBox(height: 24),

              // Tags
              _buildSectionTitle('Tags'),
              const SizedBox(height: 8),
              Text(
                'Add relevant tags to help customers find your listing',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _buildTagsSection(),
              const SizedBox(height: 24),

              // Settings
              _buildSectionTitle('Settings'),
              const SizedBox(height: 12),
              _buildSettingsCard(),
              const SizedBox(height: 32),

              // Save Button
              AppButton(
                text: _isEditing ? 'Save Changes' : 'Add Listing',
                onPressed: _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _listingTypes.map((type) {
          final isSelected = _selectedType == type['value'];
          final color = type['color'] as Color;

          return GestureDetector(
            onTap: () => setState(() => _selectedType = type['value']),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.08) : null,
                border: Border(
                  bottom: type != _listingTypes.last
                      ? const BorderSide(color: AppColors.border, width: 0.5)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.15) : AppColors.greyLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      type['icon'] as IconData,
                      color: isSelected ? color : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type['label'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isSelected ? color : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          type['hint'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Radio<String>(
                    value: type['value'] as String,
                    groupValue: _selectedType,
                    onChanged: (value) => setState(() => _selectedType = value!),
                    activeColor: color,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          AppTextField(
            controller: _nameController,
            labelText: 'Name *',
            hintText: _currentType['hint'] as String,
            prefixIcon: Icon(_currentType['icon'] as IconData),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _descriptionController,
            labelText: 'Description',
            hintText: 'Describe your ${_currentType['label'].toString().toLowerCase()} in detail',
            prefixIcon: const Icon(Iconsax.document_text),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    final showDuration = _selectedType == 'service' || _selectedType == 'booking';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: _priceController,
                  labelText: 'Price (₹)',
                  hintText: '0',
                  prefixIcon: const Icon(Iconsax.money),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: AppTextField(
                  controller: _priceUnitController,
                  labelText: 'Unit',
                  hintText: _getPriceUnitHint(),
                  prefixIcon: const Icon(Iconsax.tag),
                ),
              ),
            ],
          ),
          if (showDuration) ...[
            const SizedBox(height: 16),
            AppTextField(
              controller: _durationController,
              labelText: 'Duration (minutes)',
              hintText: 'e.g., 30, 60, 120',
              prefixIcon: const Icon(Iconsax.clock),
              keyboardType: TextInputType.number,
            ),
          ],
        ],
      ),
    );
  }

  String _getPriceUnitHint() {
    switch (_selectedType) {
      case 'service':
        return 'service';
      case 'product':
        return 'item';
      case 'rental':
        return 'day';
      case 'booking':
        return 'session';
      default:
        return 'unit';
    }
  }

  Widget _buildTagsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    hintText: 'Add a tag...',
                    filled: true,
                    fillColor: AppColors.greyLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Iconsax.add, color: AppColors.primary),
                ),
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeTag(tag),
                        child: const Icon(Icons.close, size: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Active', style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text(
              'Show this listing in search results',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            activeColor: AppColors.success,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Featured', style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text(
              'Highlight this listing (requires premium)',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            value: _isFeatured,
            onChanged: (value) => setState(() => _isFeatured = value),
            activeColor: AppColors.warning,
          ),
        ],
      ),
    );
  }
}