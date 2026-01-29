class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderType;
  final String content;
  final String messageType;
  final bool isReadable;
  final bool isRead;
  final bool isAiResponse;
  final DateTime?  readAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this. conversationId,
    required this.senderId,
    required this.senderType,
    required this.content,
    this.messageType = 'text',
    this.isReadable = false,
    this.isRead = false,
    this.isAiResponse = false,
    this.readAt,
    this. metadata = const {},
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderType:  json['sender_type'] ?? 'user',
      content: json['content'] ?? '',
      messageType:  json['message_type'] ?? 'text',
      isReadable: json['is_readable'] ??  false,
      isRead: json['is_read'] ?? false,
      isAiResponse: json['is_ai_response'] ??  false,
      readAt: json['read_at'] != null ?  DateTime.parse(json['read_at']) : null,
      metadata: json['metadata'] ??  {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_type': senderType,
      'content': content,
      'message_type': messageType,
      'is_readable': isReadable,
      'is_read': isRead,
      'is_ai_response': isAiResponse,
      'read_at': readAt?.toIso8601String(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderType,
    String? content,
    String? messageType,
    bool?  isReadable,
    bool?  isRead,
    bool? isAiResponse,
    DateTime?  readAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this. id,
      conversationId:  conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      isReadable: isReadable ??  this.isReadable,
      isRead: isRead ?? this. isRead,
      isAiResponse: isAiResponse ?? this.isAiResponse,
      readAt: readAt ?? this. readAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Computed properties
  bool get isFromUser => senderType == 'user';
  bool get isFromProfessional => senderType == 'professional';
  bool get isSystemMessage => senderType == 'system';
  bool get isAI => senderType == 'ai' || isAiResponse;
  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isFile => messageType == 'file';

  bool isMine(String currentUserId) => senderId == currentUserId;

  String get timeDisplay {
    final hour = createdAt.hour;
    final minute = createdAt.minute. toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get dateDisplay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  @override
  String toString() => 'MessageModel(id: $id, senderType: $senderType, content: ${content.substring(0, content.length > 30 ? 30 : content. length)}...)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}