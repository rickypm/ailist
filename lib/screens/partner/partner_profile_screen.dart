import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class PartnerProfileScreen extends StatefulWidget {
  const PartnerProfileScreen({super.key});

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _professionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _areaController = TextEditingController();
  final _experienceController = TextEditingController();
  final _storageService = StorageService();

  File? _selectedAvatar;
  File? _selectedCover;
  String? _currentAvatarUrl;
  String? _currentCoverUrl;
  String _selectedCity = AppConfig.defaultCity;
  String _partnerType = 'individual';
  List<String> _services = [];
  bool _isLoading = false;
  bool _isUploading = false;

  final _serviceController = TextEditingController();

  final List<String> _cities = [
    'Shillong',
    'Guwahati',
    'Tura',
    'Jowai',
    'Nongstoin',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final dataProvider = context.read<DataProvider>();
    final professional = dataProvider.selectedProfessional;

    if (professional != null) {
      _displayNameController.text = professional.displayName;
      _professionController.text = professional.profession;
      _descriptionController.text = professional.description ?? '';
      _phoneController.text = professional.phone ?? '';
      _whatsappController.text = professional.whatsapp ?? '';
      _emailController.text = professional.email ?? '';
      _areaController.text = professional.area ?? '';
      _experienceController.text = professional.experienceYears.toString();
      _selectedCity = professional.city;
      _partnerType = professional.partnerType;
      _services = List.from(professional.services);
      _currentAvatarUrl = professional.avatarUrl;
      _currentCoverUrl = professional.coverUrl;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _professionController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _areaController.dispose();
    _experienceController.dispose();
    _serviceController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await _storageService.pickImage();
    if (file != null) {
      setState(() => _selectedAvatar = file);
    }
  }

  Future<void> _pickCover() async {
    final file = await _storageService.pickImage();
    if (file != null) {
      setState(() => _selectedCover = file);
    }
  }

  void _addService() {
    final service = _serviceController.text.trim();
    if (service.isNotEmpty && !_services.contains(service)) {
      setState(() {
        _services.add(service);
        _serviceController.clear();
      });
    }
  }

  void _removeService(String service) {
    setState(() => _services.remove(service));
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dataProvider = context.read<DataProvider>();
    final authProvider = context.read<AuthProvider>();
    final professional = dataProvider.selectedProfessional;

    // Get user ID
    final userId = authProvider.user?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error: User not logged in'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String? avatarUrl;
    String? coverUrl;

    // Upload avatar if selected
    if (_selectedAvatar != null) {
      setState(() => _isUploading = true);
      avatarUrl = await _storageService.uploadAvatar(
        file: _selectedAvatar!,
        odId: professional?.id ?? userId,
      );
    } else {
      avatarUrl = _currentAvatarUrl;
    }

    // Upload cover if selected
    if (_selectedCover != null) {
      coverUrl = await _storageService.uploadImage(
        _selectedCover!,
        'covers/${professional?.id ?? userId}',
      );
    } else {
      coverUrl = _currentCoverUrl;
    }

    setState(() => _isUploading = false);

    // Prepare data
    final data = {
      'user_id': userId,
      'display_name': _displayNameController.text.trim(),
      'profession': _professionController.text.trim(),
      'description': _descriptionController.text.trim(),
      'phone': _phoneController.text.trim(),
      'whatsapp': _whatsappController.text.trim(),
      'email': _emailController.text.trim(),
      'city': _selectedCity,
      'area': _areaController.text.trim(),
      'experience_years': int.tryParse(_experienceController.text) ?? 0,
      'partner_type': _partnerType,
      'services': _services,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (coverUrl != null) 'cover_url': coverUrl,
    };

    bool success;

    if (professional == null) {
      // CREATE new professional profile
      debugPrint('Creating new professional profile...');
      success = await dataProvider.createProfessionalProfile(data);
    } else {
      // UPDATE existing professional profile
      debugPrint('Updating existing professional profile...');
      success = await dataProvider.updateProfessionalProfile(data);
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(professional == null
              ? 'Profile created successfully!'
              : 'Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile. ${dataProvider.error ?? ""}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: AppTextStyles.h3),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
              // Cover Image
              _buildCoverImage(),
              const SizedBox(height: 24),

              // Avatar
              _buildAvatar(),
              const SizedBox(height: 32),

              // Basic Info Section
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),

              AppTextField(
                controller: _displayNameController,
                labelText: 'Display Name',
                hintText: 'Your business/professional name',
                prefixIcon: const Icon(Iconsax.user),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _professionController,
                labelText: 'Profession',
                hintText: 'e.g., Electrician, Plumber, Tutor',
                prefixIcon: const Icon(Iconsax.briefcase),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your profession';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _descriptionController,
                labelText: 'About',
                hintText: 'Describe your services...',
                prefixIcon: const Icon(Iconsax.document_text),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Contact Section
              _buildSectionTitle('Contact Information'),
              const SizedBox(height: 16),

              AppTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                hintText: 'Your contact number',
                prefixIcon: const Icon(Iconsax.call),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _whatsappController,
                labelText: 'WhatsApp Number',
                hintText: 'Your WhatsApp number',
                prefixIcon: const Icon(Iconsax.message),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'Your email address',
                prefixIcon: const Icon(Iconsax.sms),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              // Location Section
              _buildSectionTitle('Location'),
              const SizedBox(height: 16),

              _buildCityDropdown(),
              const SizedBox(height: 16),

              AppTextField(
                controller: _areaController,
                labelText: 'Area/Locality',
                hintText: 'Your area or locality',
                prefixIcon: const Icon(Iconsax.location),
              ),
              const SizedBox(height: 24),

              // Experience Section
              _buildSectionTitle('Experience'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _experienceController,
                      labelText: 'Years of Experience',
                      hintText: '0',
                      prefixIcon: const Icon(Iconsax.calendar),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPartnerTypeDropdown(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Services Section
              _buildSectionTitle('Services Offered'),
              const SizedBox(height: 16),
              _buildServicesSection(),
              const SizedBox(height: 40),

              // Save Button
              AppButton(
                text: 'Save Changes',
                onPressed: _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    return GestureDetector(
      onTap: _pickCover,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          image: _selectedCover != null
              ? DecorationImage(
                  image: FileImage(_selectedCover!),
                  fit: BoxFit.cover,
                )
              : _currentCoverUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_currentCoverUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
        ),
        child: _selectedCover == null && _currentCoverUrl == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.image, color: AppColors.textMuted, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Add Cover Photo',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.camera, color: AppColors.white, size: 20),
                ),
              ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.inputBorderGradient,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: _selectedAvatar != null
                    ? Image.file(_selectedAvatar!, fit: BoxFit.cover, width: 94, height: 94)
                    : _currentAvatarUrl != null
                        ? Image.network(
                            _currentAvatarUrl!,
                            fit: BoxFit.cover,
                            width: 94,
                            height: 94,
                            errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                          )
                        : _buildAvatarPlaceholder(),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 3),
                ),
                child: const Icon(Iconsax.camera, color: AppColors.white, size: 16),
              ),
            ),
          ),
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 94,
      height: 94,
      color: AppColors.surfaceLight,
      child: const Icon(Iconsax.user, color: AppColors.textMuted, size: 40),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'City',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCity,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              icon: const Icon(Iconsax.arrow_down_1, color: AppColors.textMuted),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
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
    );
  }

  Widget _buildPartnerTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _partnerType,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              icon: const Icon(Iconsax.arrow_down_1, color: AppColors.textMuted),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              items: const [
                DropdownMenuItem(value: 'individual', child: Text('Individual')),
                DropdownMenuItem(value: 'group', child: Text('Team/Group')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _partnerType = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Service Input
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _serviceController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add a service...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _addService(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _addService,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.add, color: AppColors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Services List
        if (_services.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _services.map((service) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removeService(service),
                      child: Icon(
                        Iconsax.close_circle,
                        size: 16,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
        else
          Text(
            'No services added yet',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
      ],
    );
  }
}