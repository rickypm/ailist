import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../messages/chat_screen.dart';
import '../subscription/subscription_screen.dart';

class PartnerInboxScreen extends StatefulWidget {
  const PartnerInboxScreen({super.key});

  @override
  State<PartnerInboxScreen> createState() => _PartnerInboxScreenState();
}

class _PartnerInboxScreenState extends State<PartnerInboxScreen> {
  bool _isInitialized = false;
  String _debugInfo = 'Loading...';  // ✅ ADDED: Debug info

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversations();
    });
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();

    // ✅ ADDED: Build debug info
    String info = '=== DEBUG INFO ===\n';
    info += 'User: ${authProvider.user?.email ?? "NULL"}\n';
    info += 'User ID: ${authProvider.user?.id ?? "NULL"}\n';
    info += 'Professional (before): ${dataProvider.selectedProfessional?.displayName ?? "NULL"}\n';

    // ✅ FIX: If professional not loaded, call initUser first
    if (dataProvider.selectedProfessional == null && authProvider.user != null) {
      info += 'Calling initUser...\n';
      await dataProvider.initUser(authProvider.user!.id);
    }

    info += 'Professional (after): ${dataProvider.selectedProfessional?.displayName ?? "NULL"}\n';
    info += 'Professional ID: ${dataProvider.selectedProfessional?.id ?? "NULL"}\n';

    // ✅ FIX: Load conversations with professional ID
    if (dataProvider.selectedProfessional != null) {
      await dataProvider.loadConversations(
        dataProvider.selectedProfessional!.id,
        isPartner: true,
      );
      info += 'Conversations loaded: ${dataProvider.conversations.length}\n';
      
      for (var conv in dataProvider.conversations) {
        info += '  - ${conv.getDisplayName(true)}: ${conv.lastMessagePreview ?? "no msg"}\n';
      }
    } else {
      info += 'ERROR: Professional is still NULL!\n';
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _debugInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final professional = dataProvider.selectedProfessional;
    final canReadMessages = _canReadMessages(professional);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadConversations,
          ),
          if (!canReadMessages)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen(isPartner: true),
                  ),
                );
              },
              icon: const Icon(Iconsax.crown, size: 18, color: AppColors.warning),
              label: const Text('Upgrade', style: TextStyle(color: AppColors.warning)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        color: AppColors.primary,
        child: Column(
          children: [
            // ✅ ADDED: Debug info box (remove this after fixing)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _debugInfo,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
            ),
            // Original body
            Expanded(
              child: _buildBody(dataProvider, canReadMessages),
            ),
          ],
        ),
      ),
    );
  }

  /// Partners need Starter or Business plan to read messages
  bool _canReadMessages(dynamic professional) {
    if (professional == null) return false;
    final plan = (professional.subscriptionPlan ?? 'free').toString().toLowerCase();
    return plan == 'starter' || plan == 'business';
  }

  Widget _buildBody(DataProvider dataProvider, bool canReadMessages) {
    if (!_isInitialized || dataProvider.conversationsLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ShimmerListTile(),
          );
        },
      );
    }

    if (dataProvider.conversations.isEmpty) {
      return EmptyState(
        icon: Iconsax.message,
        title: 'No messages yet',
        subtitle: 'Customer inquiries will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: dataProvider.conversations.length,
      itemBuilder: (context, index) {
        final conversation = dataProvider.conversations[index];
        return _buildConversationTile(conversation, canReadMessages);
      },
    );
  }

  Widget _buildConversationTile(dynamic conversation, bool canReadMessages) {
    final hasUnread = conversation.professionalUnreadCount > 0;
    
    // ✅ FIX: Use correct property names from ConversationModel
    final userName = conversation.getDisplayName(true); // true = partner view
    final userAvatar = conversation.getAvatarUrl(true);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          AvatarWidget(
            imageUrl: userAvatar,
            name: userName,
            size: 52,
          ),
          // Show lock icon if can't read
          if (!canReadMessages)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.lock,
                  size: 12,
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              userName,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            conversation.timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: hasUnread ? AppColors.primary : AppColors.textMuted,
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              canReadMessages 
                  ? (conversation.lastMessagePreview ?? 'No messages yet')
                  : '🔒 Upgrade to read messages',
              style: TextStyle(
                fontSize: 13,
                color: canReadMessages 
                    ? (hasUnread ? AppColors.textPrimary : AppColors.textSecondary)
                    : AppColors.warning,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.professionalUnreadCount > 9
                    ? '9+'
                    : conversation.professionalUnreadCount.toString(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversation: conversation,
              isPartnerView: true,
            ),
          ),
        ).then((_) => _loadConversations());
      },
    );
  }
}