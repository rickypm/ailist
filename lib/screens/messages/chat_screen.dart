import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/conversation_model.dart';
import '../../models/professional_model.dart';
import '../../models/user_model.dart';
import '../subscription/subscription_screen.dart';

class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;
  final ProfessionalModel? professional;
  final UserModel? user; // For partner view
  final bool isPartnerView;

  const ChatScreen({
    super.key,
    required this.conversation,
    this.professional,
    this.user,
    this.isPartnerView = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  bool _canPartnerReadMessages = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadMessages();
  }

  void _checkPermissions() {
    if (widget.isPartnerView) {
      final dataProvider = context.read<DataProvider>();
      final professional = dataProvider.selectedProfessional;
      final plan = professional?.subscriptionPlan?.toLowerCase() ?? 'free';
      
      // Partners need subscription to READ messages
      // Starter and Business can read
      _canPartnerReadMessages = plan == 'starter' || plan == 'business';
    }
  }

  Future<void> _loadMessages() async {
    final dataProvider = context.read<DataProvider>();
    await dataProvider.loadMessages(widget.conversation.id);
    
    // Mark messages as read
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      final readerType = widget.isPartnerView ? 'professional' : 'user';
      await dataProvider.markMessagesAsRead(widget.conversation.id, readerType);
    }
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final authProvider = context.read<AuthProvider>();
      final dataProvider = context.read<DataProvider>();
      
      // Determine sender type based on view
      final senderType = widget.isPartnerView ? 'professional' : 'user';
      final senderId = widget.isPartnerView 
          ? dataProvider.selectedProfessional?.id ?? authProvider.user!.id
          : authProvider.user!.id;
      
      await dataProvider.sendMessage(
        conversationId: widget.conversation.id,
        senderId: senderId,
        senderType: senderType,
        content: message,
      );

      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Use correct property names from ConversationModel
    String displayName;
    String? subtitle;
    
    if (widget.isPartnerView) {
      // Partner is viewing - show user info
      // Use getDisplayName helper or otherUserName
      displayName = widget.conversation.getDisplayName(true);
      subtitle = null;
    } else {
      // User is viewing - show professional info
      displayName = widget.professional?.displayName 
          ?? widget.conversation.professionalName 
          ?? widget.conversation.getDisplayName(false);
      subtitle = widget.professional?.profession ?? widget.conversation.profession;
    }
    
    return Scaffold(
      backgroundColor: AppColors.backgroundNavy,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _buildMessagesList(),
          ),

          // Input Field or Upgrade Prompt
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    // If partner view and can't read messages, show blurred/locked view
    if (widget.isPartnerView && !_canPartnerReadMessages) {
      return _buildLockedMessagesView();
    }
    
    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        final messages = dataProvider.messages;

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.message,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation!',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            
            // Determine if message is from "me" based on view type
            final isMe = widget.isPartnerView 
                ? message.senderType == 'professional'
                : message.senderType == 'user';

            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : AppColors.surfaceNavy,
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomRight: isMe ? const Radius.circular(4) : null,
                    bottomLeft: !isMe ? const Radius.circular(4) : null,
                  ),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? AppColors.white : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLockedMessagesView() {
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
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.lock,
                size: 40,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Messages Locked',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have new messages from customers!\nUpgrade to Starter or Business to read and reply.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen(isPartner: true),
                  ),
                );
              },
              icon: const Icon(Iconsax.crown),
              label: const Text('Upgrade Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    // Partner without subscription can't reply, but users always can
    if (widget.isPartnerView && !_canPartnerReadMessages) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surfaceNavy,
          border: Border(top: BorderSide(color: AppColors.borderNavy)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              const Icon(Iconsax.lock, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Upgrade to reply to messages',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(isPartner: true),
                    ),
                  );
                },
                child: const Text('Upgrade'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Normal input field
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceNavy,
        border: Border(top: BorderSide(color: AppColors.borderNavy)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.backgroundNavy,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(
                        Iconsax.send_1,
                        color: AppColors.white,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}