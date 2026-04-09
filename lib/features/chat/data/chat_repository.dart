import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/chat_models.dart';
import 'chat_seed_data.dart';

/// Abstract repository for chat operations
abstract class ChatRepository {
  /// Load all conversations for current user (ordered by lastMessageAt)
  Future<List<ConversationListItem>> loadConversations({
    required String userId,
    required int limit,
  });

  /// Load a specific conversation with all its messages and responses
  Future<ChatThread> loadThread({
    required String conversationId,
    required String currentUserId,
  });

  /// Send a new message
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required String content,
    required MessageContentType contentType,
    required MessageRole senderRole,
    bool requiresResponse = false,
    String? mediaUrl,
    String? mediaFileName,
    String? mediaMimeType,
  });

  /// Respond to a "requires response" message
  Future<MessageResponse> respondToMessage({
    required String messageId,
    required String conversationId,
    required String responderId,
    required ResponseAction action,
    String? additionalMessage,
  });

  /// Mark messages as read
  Future<void> markAsRead({
    required List<String> messageIds,
  });

  /// Update unread count for a conversation
  Future<void> updateUnreadCount({
    required String conversationId,
    required int count,
  });
}

/// SQLite implementation of ChatRepository
class SqliteChatRepository extends ChatRepository {
  static const _dbName = 'gappsdd.sqlite';
  static const _dbVersion = 3; // Incremented due to chat tables

  Database? _database;
  Future<Database>? _opening;

  Future<Database> _db() async {
    if (_database != null) {
      return _database!;
    }
    if (_opening != null) {
      return _opening!;
    }

    _opening = _open();
    _database = await _opening!;
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrateSchema(db, oldVersion, newVersion);
      },
      onOpen: (db) async {
        await ChatSeedDataLoader.loadForAppStartup(db);
      },
    );
  }

  Future<void> _migrateSchema(Database db, int oldVersion, int newVersion) async {
    // Add chat migrations here as needed
    if (oldVersion < 3) {
      // In actual implementation, would add chat tables
    }
  }

  Future<void> _createSchema(Database db) async {
    // Conversations table
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        gardener_id TEXT NOT NULL,
        client_id TEXT NOT NULL,
        visit_id TEXT,
        garden_id TEXT,
        status TEXT DEFAULT 'ACTIVE' CHECK(status IN ('ACTIVE', 'ARCHIVED')),
        last_message_at TEXT,
        unread_message_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(gardener_id, client_id)
      )
    ''');

    await db.execute('CREATE INDEX idx_conversations_gardener ON conversations(gardener_id)');
    await db.execute('CREATE INDEX idx_conversations_client ON conversations(client_id)');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        recipient_id TEXT NOT NULL,
        sender_role TEXT NOT NULL CHECK(sender_role IN ('GARDENER', 'CLIENT')),
        content_type TEXT NOT NULL CHECK(content_type IN ('TEXT', 'IMAGE', 'DOCUMENT')),
        content TEXT,
        media_url TEXT,
        media_file_name TEXT,
        media_mime_type TEXT,
        created_at TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        read_at TEXT,
        requires_response INTEGER DEFAULT 0,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id)
      )
    ''');

    await db.execute('CREATE INDEX idx_messages_conversation ON messages(conversation_id)');
    await db.execute('CREATE INDEX idx_messages_sender ON messages(sender_id)');
    await db.execute('CREATE INDEX idx_messages_recipient ON messages(recipient_id)');
    await db.execute('CREATE INDEX idx_messages_created_at ON messages(created_at)');

    // MessageResponses table
    await db.execute('''
      CREATE TABLE message_responses (
        id TEXT PRIMARY KEY,
        message_id TEXT NOT NULL,
        conversation_id TEXT NOT NULL,
        responder_id TEXT NOT NULL,
        responder_role TEXT DEFAULT 'CLIENT',
        action TEXT NOT NULL CHECK(action IN ('ACCEPT', 'REJECT', 'MORE_INFO')),
        additional_message TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (message_id) REFERENCES messages(id),
        FOREIGN KEY (conversation_id) REFERENCES conversations(id)
      )
    ''');

    await db.execute('CREATE INDEX idx_responses_message ON message_responses(message_id)');
    await db.execute('CREATE INDEX idx_responses_conversation ON message_responses(conversation_id)');
  }

  @override
  Future<List<ConversationListItem>> loadConversations({
    required String userId,
    required int limit,
  }) async {
    final db = await _db();

    final results = await db.rawQuery('''
      SELECT 
        c.id,
        c.gardener_id,
        c.client_id,
        c.last_message_at,
        c.unread_message_count,
        m.content as last_message_preview
      FROM conversations c
      LEFT JOIN messages m ON c.id = m.conversation_id 
        AND m.id = (
          SELECT id FROM messages 
          WHERE conversation_id = c.id 
          ORDER BY created_at DESC LIMIT 1
        )
      WHERE c.gardener_id = ? OR c.client_id = ?
      ORDER BY c.last_message_at DESC NULLS LAST
      LIMIT ?
    ''', [userId, userId, limit]);

    return results.map((row) {
      final gardenerId = row['gardener_id'] as String;
      final clientId = row['client_id'] as String;
      final otherUserId = gardenerId == userId ? clientId : gardenerId;

      return ConversationListItem(
        conversationId: row['id'] as String,
        otherUserId: otherUserId,
        otherUserName: otherUserId, // TODO: Join with user table
        otherUserAvatarUrl: '', // TODO: Join with user table
        lastMessagePreview: (row['last_message_preview'] as String?) ?? '',
        lastMessageAt: DateTime.parse((row['last_message_at'] as String?) ?? ''),
        unreadCount: (row['unread_message_count'] as int?) ?? 0,
      );
    }).toList();
  }

  @override
  Future<ChatThread> loadThread({
    required String conversationId,
    required String currentUserId,
  }) async {
    final db = await _db();

    // Load conversation metadata (for contact info)
    final convResults = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    if (convResults.isEmpty) {
      throw Exception('Conversation not found');
    }

    final conv = convResults.first;
    final gardenerId = conv['gardener_id'] as String;
    final clientId = conv['client_id'] as String;
    final otherUserId = gardenerId == currentUserId ? clientId : gardenerId;

    // Load messages
    final msgResults = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );

    final messages = msgResults.map((row) {
      return Message(
        id: row['id'] as String,
        conversationId: row['conversation_id'] as String,
        senderId: row['sender_id'] as String,
        recipientId: row['recipient_id'] as String,
        senderRole: _roleFromString(row['sender_role'] as String),
        contentType: _contentTypeFromString(row['content_type'] as String),
        content: row['content'] as String? ?? '',
        createdAt: DateTime.parse(row['created_at'] as String),
        mediaUrl: row['media_url'] as String?,
        mediaFileName: row['media_file_name'] as String?,
        mediaMimeType: row['media_mime_type'] as String?,
        isRead: (row['is_read'] as int?) == 1,
        readAt: row['read_at'] != null ? DateTime.parse(row['read_at'] as String) : null,
        requiresResponse: (row['requires_response'] as int?) == 1,
      );
    }).toList();

    // Load responses
    final respResults = await db.query(
      'message_responses',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );

    final responses = <String, MessageResponse>{};
    for (final row in respResults) {
      final resp = MessageResponse(
        id: row['id'] as String,
        messageId: row['message_id'] as String,
        conversationId: row['conversation_id'] as String,
        responderId: row['responder_id'] as String,
        action: _actionFromString(row['action'] as String),
        createdAt: DateTime.parse(row['created_at'] as String),
        additionalMessage: row['additional_message'] as String?,
        updatedAt: row['updated_at'] != null ? DateTime.parse(row['updated_at'] as String) : null,
      );
      responses[resp.messageId] = resp;
    }

    // Mark as read
    await markAsRead(
      messageIds: messages.where((m) => !m.isRead).map((m) => m.id).toList(),
    );

    return ChatThread(
      conversationId: conversationId,
      contactName: otherUserId, // TODO: Join with user table
      contactAvatarUrl: '', // TODO: Join with user table
      contactRole: gardenerId == otherUserId ? 'Gardener' : 'Client',
      messages: messages,
      responses: responses,
    );
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required String content,
    required MessageContentType contentType,
    required MessageRole senderRole,
    bool requiresResponse = false,
    String? mediaUrl,
    String? mediaFileName,
    String? mediaMimeType,
  }) async {
    final db = await _db();
    final messageId = const Uuid().v4();
    final now = DateTime.now();

    await db.insert('messages', {
      'id': messageId,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'sender_role': _roleToString(senderRole),
      'content_type': _contentTypeToString(contentType),
      'content': content,
      'media_url': mediaUrl,
      'media_file_name': mediaFileName,
      'media_mime_type': mediaMimeType,
      'created_at': now.toIso8601String(),
      'is_read': 0,
      'requires_response': requiresResponse ? 1 : 0,
    });

    // Update conversation last_message_at
    await db.update(
      'conversations',
      {'last_message_at': now.toIso8601String(), 'updated_at': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    return Message(
      id: messageId,
      conversationId: conversationId,
      senderId: senderId,
      recipientId: recipientId,
      senderRole: senderRole,
      contentType: contentType,
      content: content,
      createdAt: now,
      mediaUrl: mediaUrl,
      mediaFileName: mediaFileName,
      mediaMimeType: mediaMimeType,
      requiresResponse: requiresResponse,
    );
  }

  @override
  Future<MessageResponse> respondToMessage({
    required String messageId,
    required String conversationId,
    required String responderId,
    required ResponseAction action,
    String? additionalMessage,
  }) async {
    final db = await _db();
    final responseId = const Uuid().v4();
    final now = DateTime.now();

    await db.insert('message_responses', {
      'id': responseId,
      'message_id': messageId,
      'conversation_id': conversationId,
      'responder_id': responderId,
      'responder_role': 'CLIENT',
      'action': _actionToString(action),
      'additional_message': additionalMessage,
      'created_at': now.toIso8601String(),
    });

    return MessageResponse(
      id: responseId,
      messageId: messageId,
      conversationId: conversationId,
      responderId: responderId,
      action: action,
      createdAt: now,
      additionalMessage: additionalMessage,
    );
  }

  @override
  Future<void> markAsRead({
    required List<String> messageIds,
  }) async {
    if (messageIds.isEmpty) return;

    final db = await _db();
    final now = DateTime.now();
    final placeholders = messageIds.map((_) => '?').join(',');

    await db.rawUpdate('''
      UPDATE messages 
      SET is_read = 1, read_at = ? 
      WHERE id IN ($placeholders)
    ''', [now.toIso8601String(), ...messageIds]);
  }

  @override
  Future<void> updateUnreadCount({
    required String conversationId,
    required int count,
  }) async {
    final db = await _db();
    await db.update(
      'conversations',
      {'unread_message_count': count},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  // Helper methods
  String _roleToString(MessageRole role) {
    return role == MessageRole.gardener ? 'GARDENER' : 'CLIENT';
  }

  MessageRole _roleFromString(String role) {
    return role == 'GARDENER' ? MessageRole.gardener : MessageRole.client;
  }

  String _contentTypeToString(MessageContentType type) {
    switch (type) {
      case MessageContentType.text:
        return 'TEXT';
      case MessageContentType.image:
        return 'IMAGE';
      case MessageContentType.document:
        return 'DOCUMENT';
    }
  }

  MessageContentType _contentTypeFromString(String type) {
    switch (type) {
      case 'IMAGE':
        return MessageContentType.image;
      case 'DOCUMENT':
        return MessageContentType.document;
      default:
        return MessageContentType.text;
    }
  }

  String _actionToString(ResponseAction action) {
    switch (action) {
      case ResponseAction.accept:
        return 'ACCEPT';
      case ResponseAction.reject:
        return 'REJECT';
      case ResponseAction.moreInfo:
        return 'MORE_INFO';
    }
  }

  ResponseAction _actionFromString(String action) {
    switch (action) {
      case 'ACCEPT':
        return ResponseAction.accept;
      case 'REJECT':
        return ResponseAction.reject;
      case 'MORE_INFO':
        return ResponseAction.moreInfo;
      default:
        return ResponseAction.moreInfo;
    }
  }
}