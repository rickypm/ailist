import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../models/shop_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class ShopEditorScreen extends StatefulWidget {
  final ShopModel?  shop;

  const ShopEditorScreen({
    super.key,
    this.shop,
  });

  @override
  State<ShopEditorScreen> createState() => _ShopEditorScreenState();
}

class _ShopEditorScreenState extends State<ShopEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  String _selectedCity = 'Shillong';
  bool _isLoading = false;

  final List<String> _cities = [
    'Shillong',
    'Guwahati',
    'Tura',
    'Jowai',
    'Nongstoin',
    'Williamnagar',
    'Baghmara',
    'Other',
  ];

  bool get _isEditing => widget.shop != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.shop != null) {
      // Editing existing shop - use shop data
      final shop = widget.shop!;
      _nameController.text = shop. name;
      _descriptionController.text = shop.description ??  '';
      _addressController.text = shop.address ?? '';
      _areaController.text = shop.area ?? '';
      _phoneController.text = shop.phone ??  '';
      _whatsappController.text = shop.whatsapp ?? '';
      _emailController. text = shop.email ?? '';
      _websiteController.text = shop.website ?? '';
      _selectedCity = shop.city;
    } else {
      // Creating new shop - auto-fill from professional profile
      final dataProvider = context.read<DataProvider>();
      final professional = dataProvider.selectedProfessional;

      if (professional != null) {
        _nameController.text = professional.displayName;
        _descriptionController.text = professional.description ?? '';
        _areaController.text = professional.area ?? '';
        _phoneController. text = professional.phone ?? '';
        _whatsappController.text = professional.whatsapp ?? '';
        _emailController.text = professional.email ?? '';
        _selectedCity = professional.city;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dataProvider = context.read<DataProvider>();
    final authProvider = context.read<AuthProvider>();

    // Reload professional in case it was just created
    if (authProvider.user != null && dataProvider.selectedProfessional == null) {
      await dataProvider.loadProfessionalByUserId(authProvider.user! .id);
    }

    final professional = dataProvider.selectedProfessional;

    if (professional == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your professional profile first'),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.pop(context);
      return;
    }

    final shopData = {
      'professional_id': professional.id,
      'name': _nameController. text. trim(),
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      'address': _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      'area': _areaController.text.trim().isNotEmpty
          ? _areaController.text.trim()
          : null,
      'city': _selectedCity,
      'phone': _phoneController.text. trim().isNotEmpty
          ?  _phoneController.text.trim()
          : null,
      'whatsapp': _whatsappController.text.trim().isNotEmpty
          ? _whatsappController.text.trim()
          : null,
      'email':  _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      'website':  _websiteController.text.trim().isNotEmpty
          ? _websiteController.text.trim()
          : null,
    };

    debugPrint('Creating shop with professional_id: ${professional.id}');

    bool success;
    if (_isEditing) {
      success = await dataProvider.updateShop(shopData, null, null);
    } else {
      success = await dataProvider.createShop(shopData, null, null);
    }

    if (! mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger. of(context).showSnackBar(
        SnackBar(
          content:  Text(_isEditing ? 'Shop updated!' : 'Shop created!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:  Text('Failed to save shop.  ${dataProvider.error ??  ""}'),
          backgroundColor: AppColors. error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon:  const Icon(Iconsax.arrow_left),
          onPressed:  () => Navigator.pop(context),
        ),
        title: Text(_isEditing ? 'Edit Shop' : 'Create Shop'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner for new shop
              if (! _isEditing)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.info_circle, color: AppColors.info, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'We\'ve pre-filled your profile info. You can modify it for your shop.',
                          style: TextStyle(
                            color: AppColors. info,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Shop Name Section
              Text(
                'Shop Details',
                style: Theme.of(context).textTheme.titleMedium?. copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors. textLight,
                ),
              ),
              const SizedBox(height:  16),

              AppTextField(
                controller: _nameController,
                labelText: 'Shop Name *',
                hintText: 'Enter your shop name',
                prefixIcon: const Icon(Iconsax.shop),
                validator: (value) {
                  if (value == null || value. isEmpty) {
                    return 'Please enter shop name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _descriptionController,
                labelText: 'Description',
                hintText: 'Describe your shop and services',
                prefixIcon: const Icon(Iconsax. document_text),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Location Section
              Text(
                'Location',
                style: Theme. of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _addressController,
                labelText: 'Address',
                hintText: 'Enter your shop address',
                prefixIcon: const Icon(Iconsax.location),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _areaController,
                      labelText: 'Area/Locality',
                      hintText: 'e.g., Police Bazar',
                      prefixIcon: const Icon(Iconsax.map),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:  CrossAxisAlignment.start,
                      children: [
                        Text(
                          'City *',
                          style: Theme. of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border. all(color: AppColors.surfaceLight),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCity,
                              isExpanded: true,
                              dropdownColor: AppColors.surface,
                              items: _cities.map((city) {
                                return DropdownMenuItem(
                                  value: city,
                                  child: Text(city),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedCity = value);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Contact Section (Optional - can be different from profile)
              Text(
                'Shop Contact (Optional)',
                style: Theme. of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Leave blank to use your profile contact info',
                style: TextStyle(
                  color: AppColors. textSecondary,
                  fontSize:  12,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _phoneController,
                      labelText: 'Phone',
                      hintText: '9876543210',
                      prefixIcon: const Icon(Iconsax.call),
                      keyboardType: TextInputType. phone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _whatsappController,
                      labelText: 'WhatsApp',
                      hintText: '9876543210',
                      prefixIcon: const Icon(Iconsax.message),
                      keyboardType:  TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'shop@example.com',
                prefixIcon: const Icon(Iconsax.sms),
                keyboardType:  TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _websiteController,
                labelText: 'Website',
                hintText: 'https://example.com',
                prefixIcon: const Icon(Iconsax.global),
                keyboardType: TextInputType. url,
              ),
              const SizedBox(height: 32),

              // Save Button
              AppButton(
                text: _isEditing ? 'Save Changes' : 'Create Shop',
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