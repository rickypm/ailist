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

  const ItemEditorScreen({
    super.key,
    required this.shopId,
    this.item,
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
  final _tagController = TextEditingController();

  List<String> _tags = [];
  bool _isActive = true;
  bool _isFeatured = false;
  bool _isLoading = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.item != null;

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
      _tags = List.from(item.tags);
      _isActive = item.isActive;
      _isFeatured = item.isFeatured;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _priceUnitController.dispose();
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
    setState(() {
      _tags.remove(tag);
    });
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
      'tags': _tags,
      'is_active': _isActive,
      'is_featured': _isFeatured,
    };

    debugPrint('Saving item with data: $itemData');

    bool success;
    if (_isEditing) {
      success = await dataProvider.updateItemWithTags(widget.item!.id, itemData);
    } else {
      final professional = dataProvider.selectedProfessional;
      if (professional == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Professional profile not found'),
            backgroundColor: AppColors.error,
          ),
        );
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
          content: Text(_isEditing ? 'Service updated!' : 'Service added!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save service. ${dataProvider.error ?? ""}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Service?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
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
        SnackBar(
          content: const Text('Service deleted'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete service'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEditing ? 'Edit Service' : 'Add Service'),
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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info
              Text(
                'Service Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _nameController,
                labelText: 'Service Name *',
                hintText: 'e.g., AC Repair, House Cleaning',
                prefixIcon: const Icon(Iconsax.box),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter service name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _descriptionController,
                labelText: 'Description',
                hintText: 'Describe your service in detail',
                prefixIcon: const Icon(Iconsax.document_text),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Pricing
              Text(
                'Pricing',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

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
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: AppTextField(
                      controller: _priceUnitController,
                      labelText: 'Unit',
                      hintText: 'hr, day',
                      prefixIcon: const Icon(Iconsax.clock),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tags
              Text(
                'Tags',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add relevant tags to help customers find your service',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: 'Add a tag...',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.surfaceLight),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addTag,
                    icon: const Icon(Iconsax.add_circle, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeTag(tag),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.surfaceLight),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // Settings
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Show this service in search results'),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Featured'),
                subtitle: const Text('Highlight this service (requires premium)'),
                value: _isFeatured,
                onChanged: (value) {
                  setState(() => _isFeatured = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),

              // Save Button
              AppButton(
                text: _isEditing ? 'Save Changes' : 'Add Service',
                onPressed: _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}