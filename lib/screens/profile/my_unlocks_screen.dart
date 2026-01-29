import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/professional_model.dart';
import '../services/professional_detail_screen.dart';

class MyUnlocksScreen extends StatefulWidget {
  const MyUnlocksScreen({super.key});

  @override
  State<MyUnlocksScreen> createState() => _MyUnlocksScreenState();
}

class _MyUnlocksScreenState extends State<MyUnlocksScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _unlocks = [];

  @override
  void initState() {
    super.initState();
    _loadUnlocks();
  }

  Future<void> _loadUnlocks() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;
      
      if (userId != null) {
        final dataProvider = context.read<DataProvider>();
        final unlocks = await dataProvider.getUserUnlocks(userId);
        setState(() => _unlocks = unlocks);
      }
    } catch (e) {
      debugPrint('Error loading unlocks: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToProfessional(Map<String, dynamic> unlock) async {
    final dataProvider = context.read<DataProvider>();
    final professional = await dataProvider.getProfessionalById(unlock['professional_id']);
    
    if (professional != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfessionalDetailScreen(professional: professional),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNavy,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Unlocks',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Show unlock balance
          Consumer<DataProvider>(
            builder: (context, dataProvider, _) {
              final balance = dataProvider.currentUser?.unlockBalance ?? 0;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.unlock, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '$balance left',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _unlocks.isEmpty
              ? _buildEmptyState()
              : _buildUnlocksList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceNavy,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Iconsax.unlock,
                size: 40,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Unlocks Yet',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'When you unlock a professional\'s contact, they will appear here for easy access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Iconsax.search_normal),
              label: const Text('Find Professionals'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlocksList() {
    return RefreshIndicator(
      onRefresh: _loadUnlocks,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _unlocks.length,
        itemBuilder: (context, index) {
          final unlock = _unlocks[index];
          return _buildUnlockCard(unlock);
        },
      ),
    );
  }

  Widget _buildUnlockCard(Map<String, dynamic> unlock) {
    final daysRemaining = unlock['days_remaining'] ?? 365;
    final isExpiringSoon = daysRemaining <= 30;
    
    return GestureDetector(
      onTap: () => _navigateToProfessional(unlock),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpiringSoon ? AppColors.warning.withOpacity(0.5) : AppColors.borderNavy,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      (unlock['display_name'] ?? 'P')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unlock['display_name'] ?? 'Professional',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unlock['profession'] ?? '',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                const Icon(
                  Iconsax.arrow_right_3,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Contact info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundNavy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  if (unlock['phone'] != null) ...[
                    _buildContactRow(Iconsax.call, unlock['phone'], 'Phone'),
                  ],
                  if (unlock['whatsapp'] != null) ...[
                    const SizedBox(height: 8),
                    _buildContactRow(Iconsax.message, unlock['whatsapp'], 'WhatsApp'),
                  ],
                  if (unlock['email'] != null) ...[
                    const SizedBox(height: 8),
                    _buildContactRow(Iconsax.sms, unlock['email'], 'Email'),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Expiry info
            Row(
              children: [
                Icon(
                  isExpiringSoon ? Iconsax.warning_2 : Iconsax.calendar,
                  size: 14,
                  color: isExpiringSoon ? AppColors.warning : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  isExpiringSoon 
                      ? 'Expires in $daysRemaining days' 
                      : 'Valid for $daysRemaining days',
                  style: TextStyle(
                    color: isExpiringSoon ? AppColors.warning : AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  'Unlocked ${_formatDate(unlock['unlocked_at'])}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final DateTime dateTime = date is String ? DateTime.parse(date) : date;
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) return 'today';
      if (difference.inDays == 1) return 'yesterday';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
      return '${(difference.inDays / 30).floor()} months ago';
    } catch (e) {
      return '';
    }
  }
}