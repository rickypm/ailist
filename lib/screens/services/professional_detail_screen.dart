import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/professional_model.dart';
import '../messages/chat_screen.dart';
import '../subscription/subscription_screen.dart';
import '../auth/login_screen.dart';

class ProfessionalDetailScreen extends StatefulWidget {
  final ProfessionalModel professional;

  const ProfessionalDetailScreen({
    super.key,
    required this.professional,
  });

  @override
  State<ProfessionalDetailScreen> createState() => _ProfessionalDetailScreenState();
}

class _ProfessionalDetailScreenState extends State<ProfessionalDetailScreen> {
  bool _isLoading = false;
  bool _isUnlocked = false;
  bool _checkingUnlock = true;
  String? _userPlan;

  @override
  void initState() {
    super.initState();
    _checkUnlockStatus();
    _incrementViews();
  }

  Future<void> _incrementViews() async {
    final dataProvider = context.read<DataProvider>();
    await dataProvider.incrementProfileViews(widget.professional.id);
  }

  Future<void> _checkUnlockStatus() async {
    setState(() => _checkingUnlock = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final dataProvider = context.read<DataProvider>();
      final userId = authProvider.user?.id;
      
      if (userId == null) {
        setState(() {
          _isUnlocked = false;
          _checkingUnlock = false;
        });
        return;
      }

      // Get user plan
      _userPlan = dataProvider.currentUser?.subscriptionPlan ?? 'free';
      
      // ✅ FIX: Plus and Pro users ALWAYS have unlimited access
      if (_userPlan == 'plus' || _userPlan == 'pro') {
        debugPrint('User has $_userPlan plan - unlimited access');
        setState(() {
          _isUnlocked = true;
          _checkingUnlock = false;
        });
        return;
      }

      // For basic/free users, check if already unlocked
      final isUnlocked = await dataProvider.isProfessionalUnlocked(widget.professional.id);
      
      setState(() {
        _isUnlocked = isUnlocked;
        _checkingUnlock = false;
      });
    } catch (e) {
      debugPrint('Error checking unlock status: $e');
      setState(() => _checkingUnlock = false);
    }
  }

  Future<void> _handleUnlock() async {
    final authProvider = context.read<AuthProvider>();
    
    // Check if logged in
    if (!authProvider.isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    final dataProvider = context.read<DataProvider>();
    final userId = authProvider.user!.id;
    final user = dataProvider.currentUser;
    final plan = user?.subscriptionPlan ?? 'free';
    
    // ✅ FIX: Plus and Pro users don't need to check balance
    if (plan == 'plus' || plan == 'pro') {
      // They should already be unlocked, but if somehow not, auto-unlock
      setState(() => _isUnlocked = true);
      return;
    }
    
    final balance = user?.unlockBalance ?? 0;

    // Check balance for basic/free users
    if (balance <= 0) {
      _showNoUnlocksDialog();
      return;
    }

    // Confirm unlock
    final confirmed = await _showUnlockConfirmation(balance);
    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final success = await dataProvider.unlockProfessional(userId, widget.professional.id);
      
      if (success) {
        setState(() => _isUnlocked = true);
        _showSnackBar('Contact unlocked successfully!', isSuccess: true);
      } else {
        _showSnackBar('Failed to unlock. Please try again.');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showUnlockConfirmation(int balance) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Iconsax.unlock, color: AppColors.primary),
            SizedBox(width: 12),
            Text(
              'Unlock Contact',
              style: TextStyle(color: AppColors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unlock ${widget.professional.displayName}\'s contact details?',
              style: const TextStyle(color: AppColors.white, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundNavy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.info_circle, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This will use 1 unlock. You have $balance remaining.\nValid for 1 year.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Unlock', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _showNoUnlocksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Iconsax.lock, color: AppColors.warning),
            SizedBox(width: 12),
            Text(
              'No Unlocks Left',
              style: TextStyle(color: AppColors.white, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'You\'ve used all your unlocks. Upgrade to Plus for unlimited access to all contacts.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Upgrade', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _showLoginPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderNavy,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Iconsax.login, color: AppColors.primary, size: 48),
            const SizedBox(height: 20),
            const Text(
              'Sign in Required',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please sign in to unlock contacts and message professionals.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sign In', style: TextStyle(color: AppColors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('$label copied to clipboard', isSuccess: true);
  }

  // ✅ FIX: Anyone can send messages
  Future<void> _startChat() async {
    final authProvider = context.read<AuthProvider>();
    
    if (!authProvider.isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    final dataProvider = context.read<DataProvider>();
    final userId = authProvider.user!.id;

    setState(() => _isLoading = true);

    try {
      final conversation = await dataProvider.startConversation(userId, widget.professional.id);
      
      if (conversation != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversation: conversation,
              professional: widget.professional,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Error starting chat: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final professional = widget.professional;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundNavy,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.backgroundNavy,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundNavy.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.arrow_left, color: AppColors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.backgroundNavy,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 3),
                        ),
                        child: professional.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  professional.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                                ),
                              )
                            : _buildAvatarPlaceholder(),
                      ),
                      const SizedBox(height: 12),
                      // Name & Verification
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            professional.displayName,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (professional.isVerified) ...[
                            const SizedBox(width: 8),
                            const Icon(Iconsax.verify5, color: AppColors.primary, size: 22),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        professional.profession,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Row
                  _buildStatsRow(professional),
                  
                  const SizedBox(height: 24),
                  
                  // Location
                  _buildInfoCard(
                    icon: Iconsax.location,
                    title: 'Location',
                    value: '${professional.area ?? ''}, ${professional.city}',
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Experience
                  if (professional.experienceYears > 0)
                    _buildInfoCard(
                      icon: Iconsax.briefcase,
                      title: 'Experience',
                      value: '${professional.experienceYears} years',
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  if (professional.description != null && professional.description!.isNotEmpty) ...[
                    const Text(
                      'About',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      professional.description!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Services
                  if (professional.services.isNotEmpty) ...[
                    const Text(
                      'Services',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: professional.services.map((service) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceNavy,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderNavy),
                          ),
                          child: Text(
                            service,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Contact Section (Locked/Unlocked)
                  _buildContactSection(),
                  
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Action Button
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        widget.professional.displayName.isNotEmpty
            ? widget.professional.displayName[0].toUpperCase()
            : 'P',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildStatsRow(ProfessionalModel professional) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Iconsax.star1,
            value: professional.rating.toStringAsFixed(1),
            label: 'Rating',
            iconColor: AppColors.warning,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Iconsax.message_text,
            value: '${professional.totalReviews}',
            label: 'Reviews',
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Iconsax.eye,
            value: '${professional.profileViews}',
            label: 'Views',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    Color? iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.borderNavy,
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    if (_checkingUnlock) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_isUnlocked) {
      return _buildUnlockedContact();
    } else {
      return _buildLockedContact();
    }
  }

  Widget _buildLockedContact() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderNavy),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundNavy,
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.lock, color: AppColors.textMuted, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Contact Locked',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock to see phone, WhatsApp, and email',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleUnlock,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : const Icon(Iconsax.unlock),
              label: Text(_isLoading ? 'Unlocking...' : 'Unlock Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedContact() {
    final professional = widget.professional;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.unlock, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Contact Unlocked',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_userPlan == 'plus' || _userPlan == 'pro')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _userPlan == 'pro' ? 'PRO' : 'PLUS',
                    style: const TextStyle(color: AppColors.primary, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Phone
          if (professional.phone != null && professional.phone!.isNotEmpty)
            _buildContactItem(
              icon: Iconsax.call,
              label: 'Phone',
              value: professional.phone!,
              onTap: () => _makeCall(professional.phone!),
              onLongPress: () => _copyToClipboard(professional.phone!, 'Phone'),
            ),
          
          // WhatsApp
          if (professional.whatsapp != null && professional.whatsapp!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildContactItem(
              icon: Iconsax.message,
              label: 'WhatsApp',
              value: professional.whatsapp!,
              onTap: () => _openWhatsApp(professional.whatsapp!),
              onLongPress: () => _copyToClipboard(professional.whatsapp!, 'WhatsApp'),
              iconColor: const Color(0xFF25D366),
            ),
          ],
          
          // Email
          if (professional.email != null && professional.email!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildContactItem(
              icon: Iconsax.sms,
              label: 'Email',
              value: professional.email!,
              onTap: () => _sendEmail(professional.email!),
              onLongPress: () => _copyToClipboard(professional.email!, 'Email'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundNavy,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(color: AppColors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceNavy,
        border: Border(top: BorderSide(color: AppColors.borderNavy)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Message Button - ✅ Always available (anyone can message)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _startChat,
                icon: const Icon(Iconsax.message),
                label: const Text('Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            // Call Button (only if unlocked)
            if (_isUnlocked && widget.professional.phone != null) ...[
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _makeCall(widget.professional.phone!),
                  icon: const Icon(Iconsax.call, color: AppColors.success),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
            
            // WhatsApp Button (only if unlocked)
            if (_isUnlocked && widget.professional.whatsapp != null) ...[
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _openWhatsApp(widget.professional.whatsapp!),
                  icon: const Icon(Iconsax.message, color: Color(0xFF25D366)),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}