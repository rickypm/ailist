import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_loading.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  final bool initialPartnerView;
  
  const InboxScreen({
    super.key,
    this.initialPartnerView = false,
  });

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;
  bool _isPartner = false;
  
  // Separate lists for user and partner conversations
  List<dynamic> _userConversations = [];
  List<dynamic> _partnerConversations = [];
  bool _loadingUser = false;
  bool _loadingPartner = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialPartnerView ? 1 : 0,
    );
    _tabController.addListener(_onTabChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfPartner();
      _loadAllConversations();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkIfPartner() async {
    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();
    
    if (authProvider.user != null) {
      // Check if user has a professional profile
      if (dataProvider.selectedProfessional == null) {
        await dataProvider.loadProfessionalByUserId(authProvider.user!.id);
      }
      
      if (mounted) {
        setState(() {
          _isPartner = dataProvider.selectedProfessional != null;
        });
      }
    }
  }

  Future<void> _loadAllConversations() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();

    if (authProvider.user == null) return;

    // Load user conversations (My Requests)
    setState(() => _loadingUser = true);
    try {
      await dataProvider.loadConversations(authProvider.user!.id, isPartner: false);
      _userConversations = List.from(dataProvider.conversations);
    } catch (e) {
      debugPrint('Error loading user conversations: $e');
    }
    if (mounted) setState(() => _loadingUser = false);

    // Load partner conversations (Client Inbox) if user is a partner
    if (dataProvider.selectedProfessional != null) {
      setState(() => _loadingPartner = true);
      try {
        await dataProvider.loadConversations(
          dataProvider.selectedProfessional!.id,
          isPartner: true,
        );
        _partnerConversations = List.from(dataProvider.conversations);
      } catch (e) {
        debugPrint('Error loading partner conversations: $e');
      }
      if (mounted) setState(() => _loadingPartner = false);
    }

    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _refreshCurrentTab() async {
    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();

    if (authProvider.user == null) return;

    if (_tabController.index == 0) {
      // Refresh My Requests
      setState(() => _loadingUser = true);
      await dataProvider.loadConversations(authProvider.user!.id, isPartner: false);
      _userConversations = List.from(dataProvider.conversations);
      if (mounted) setState(() => _loadingUser = false);
    } else {
      // Refresh Client Inbox
      if (dataProvider.selectedProfessional != null) {
        setState(() => _loadingPartner = true);
        await dataProvider.loadConversations(
          dataProvider.selectedProfessional!.id,
          isPartner: true,
        );
        _partnerConversations = List.from(dataProvider.conversations);
        if (mounted) setState(() => _loadingPartner = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        title: Text('Inbox', style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: AppColors.white),
            onPressed: _refreshCurrentTab,
          ),
        ],
        bottom: _isPartner
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.send_2, size: 18),
                        const SizedBox(width: 8),
                        const Text('My Requests'),
                        if (_getUserUnreadCount() > 0) ...[
                          const SizedBox(width: 8),
                          _buildBadge(_getUserUnreadCount()),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.people, size: 18),
                        const SizedBox(width: 8),
                        const Text('Clients'),
                        if (_getPartnerUnreadCount() > 0) ...[
                          const SizedBox(width: 8),
                          _buildBadge(_getPartnerUnreadCount()),
                        ],
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
      body: _isPartner
          ? TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: My Requests (user conversations)
                RefreshIndicator(
                  onRefresh: _refreshCurrentTab,
                  color: AppColors.primary,
                  child: _buildConversationList(
                    conversations: _userConversations,
                    isLoading: _loadingUser,
                    isPartnerView: false,
                    emptyTitle: 'No requests yet',
                    emptySubtitle: 'Start a conversation by contacting a service provider',
                  ),
                ),
                // Tab 2: Client Inbox (partner conversations)
                RefreshIndicator(
                  onRefresh: _refreshCurrentTab,
                  color: AppColors.primary,
                  child: _buildConversationList(
                    conversations: _partnerConversations,
                    isLoading: _loadingPartner,
                    isPartnerView: true,
                    emptyTitle: 'No client messages yet',
                    emptySubtitle: 'Customer inquiries will appear here',
                  ),
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: _refreshCurrentTab,
              color: AppColors.primary,
              child: _buildConversationList(
                conversations: _userConversations,
                isLoading: _loadingUser,
                isPartnerView: false,
                emptyTitle: 'No messages yet',
                emptySubtitle: 'Start a conversation by contacting a service provider',
              ),
            ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 9 ? '9+' : count.toString(),
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  int _getUserUnreadCount() {
    int count = 0;
    for (var conv in _userConversations) {
      count += (conv.userUnreadCount ?? 0) as int;
    }
    return count;
  }

  int _getPartnerUnreadCount() {
    int count = 0;
    for (var conv in _partnerConversations) {
      count += (conv.professionalUnreadCount ?? 0) as int;
    }
    return count;
  }

  Widget _buildConversationList({
    required List<dynamic> conversations,
    required bool isLoading,
    required bool isPartnerView,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (!_isInitialized || isLoading) {
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

    if (conversations.isEmpty) {
      return EmptyState(
        icon: Iconsax.message,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _buildConversationTile(conversation, isPartnerView);
      },
    );
  }

  Widget _buildConversationTile(dynamic conversation, bool isPartnerView) {
    final hasUnread = isPartnerView
        ? conversation.professionalUnreadCount > 0
        : conversation.userUnreadCount > 0;
    
    final displayName = conversation.getDisplayName(isPartnerView);
    final avatarUrl = conversation.getAvatarUrl(isPartnerView);
    final unreadCount = isPartnerView
        ? conversation.professionalUnreadCount
        : conversation.userUnreadCount;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: AvatarWidget(
        imageUrl: avatarUrl,
        name: displayName,
        size: 52,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
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
          // Show icon to indicate type
          Icon(
            isPartnerView ? Iconsax.user : Iconsax.briefcase,
            size: 14,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              conversation.lastMessagePreview ?? 'No messages yet',
              style: TextStyle(
                fontSize: 13,
                color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
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
                unreadCount > 9 ? '9+' : unreadCount.toString(),
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
              isPartnerView: isPartnerView,
            ),
          ),
        ).then((_) => _refreshCurrentTab());
      },
    );
  }
}