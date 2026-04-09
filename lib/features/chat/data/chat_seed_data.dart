import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/chat_models.dart';

/// Seed data loader for chat tables
class ChatSeedDataLoader {
  static const _uuid = Uuid();

  static Future<void> loadForAppStartup(Database db) async {
    // Check if data already exists
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM conversations');
    if ((count.first['count'] as int) > 0) {
      return; // Already loaded
    }

    // Load seed conversations
    await _loadSeedConversations(db);
  }

  static Future<void> _loadSeedConversations(Database db) async {
    // Current user (jardinero)
    const currentUserId = 'gardener-001';
    
    // Sample clients
    const clientIds = ['client-001', 'client-002', 'client-003'];
    const clientNames = ['Juan Martinez', 'Sofia Garcia', 'Maria Fernandez'];

    for (int i = 0; i < clientIds.length; i++) {
      final conversationId = _uuid.v4();
      final clientId = clientIds[i];
      final clientName = clientNames[i];
      
      final now = DateTime.now();
      final baseTime = now.subtract(Duration(days: 7 - i)).toIso8601String();

      // Create conversation
      await db.insert('conversations', {
        'id': conversationId,
        'gardener_id': currentUserId,
        'client_id': clientId,
        'status': 'ACTIVE',
        'last_message_at': baseTime,
        'unread_message_count': i == 0 ? 2 : 0, // First one has unread
        'created_at': now.subtract(Duration(days: 30)).toIso8601String(),
        'updated_at': baseTime,
      });

      // Create seed messages
      final messages = _getSampleMessagesForConversation(i);
      for (final msg in messages) {
        await db.insert('conversations', msg);
      }

      // Create sample responses
      final responses = _getSampleResponsesForConversation(i);
      for (final resp in responses) {
        await db.insert('message_responses', resp);
      }
    }
  }

  static List<Map<String, dynamic>> _getSampleMessagesForConversation(int index) {
    const currentUserId = 'gardener-001';
    final clientId = ['client-001', 'client-002', 'client-003'][index];
    final conversationId = _uuid.v4(); // TODO: Match with conversation
    final now = DateTime.now();
    
    final messages = <Map<String, dynamic>>[];

    switch (index) {
      case 0: // Juan Martinez - recent with request
        messages.add({
          'id': _uuid.v4(),
          'conversation_id': conversationId,
          'sender_id': currentUserId,
          'recipient_id': clientId,
          'sender_role': 'GARDENER',
          'content_type': 'TEXT',
          'content': 'He terminado la poda en Villa Hortensia. Se ve bien.',
          'created_at': now.subtract(Duration(hours: 3)).toIso8601String(),
          'is_read': 0,
          'requires_response': 0,
        });

        messages.add({
          'id': _uuid.v4(),
          'conversation_id': conversationId,
          'sender_id': currentUserId,
          'recipient_id': clientId,
          'sender_role': 'GARDENER',
          'content_type': 'TEXT',
          'content': '¿Apruebo riego adicional? Costo: 25€',
          'created_at': now.subtract(Duration(hours: 2, minutes: 45)).toIso8601String(),
          'is_read': 0,
          'requires_response': 1,
        });

        messages.add({
          'id': _uuid.v4(),
          'conversation_id': conversationId,
          'sender_id': clientId,
          'recipient_id': currentUserId,
          'sender_role': 'CLIENT',
          'content_type': 'TEXT',
          'content': 'Sí, adelante con el riego.',
          'created_at': now.subtract(Duration(hours: 2)).toIso8601String(),
          'is_read': 1,
          'requires_response': 0,
        });
        break;

      case 1: // Sofia Garcia - older conversation
        messages.add({
          'id': _uuid.v4(),
          'conversation_id': conversationId,
          'sender_id': currentUserId,
          'recipient_id': clientId,
          'sender_role': 'GARDENER',
          'content_type': 'TEXT',
          'content': 'Trabajo completado en Jardín Central. Adjunto fotos.',
          'created_at': now.subtract(Duration(days: 3)).toIso8601String(),
          'is_read': 1,
          'requires_response': 0,
        });

        messages.add({
          'id': _uuid.v4(),
          'conversation_id': conversationId,
          'sender_id': clientId,
          'recipient_id': currentUserId,
          'sender_role': 'CLIENT',
          'content_type': 'TEXT',
          'content': 'Gracias, se ve perfecto!',
          'created_at': now.subtract(Duration(days: 2, hours: 20)).toIso8601String(),
          'is_read': 1,
          'requires_response': 0,
        });
        break;

      case 2: // Maria Fernandez - budget discussion
        messages.add({
          'id': _uuid.v4(),
          'conversation_id': conversationId,
          'sender_id': currentUserId,
          'recipient_id': clientId,
          'sender_role': 'GARDENER',
          'content_type': 'TEXT',
          'content': 'Presupuesto para mantenimiento anual: 1200€',
          'created_at': now.subtract(Duration(days: 6)).toIso8601String(),
          'is_read': 1,
          'requires_response': 1,
        });

        messages.add({
          'id': _uuid.v4(),
          'conversation_id': conversationId,
          'sender_id': clientId,
          'recipient_id': currentUserId,
          'sender_role': 'CLIENT',
          'content_type': 'TEXT',
          'content': '¿Puedes incluir tratamiento antiplagas?',
          'created_at': now.subtract(Duration(days: 5, hours: 18)).toIso8601String(),
          'is_read': 1,
          'requires_response': 0,
        });
        break;
    }

    return messages;
  }

  static List<Map<String, dynamic>> _getSampleResponsesForConversation(int index) {
    const clientId = 'client-001'; // Only first conversation has responses
    const conversationId = ''; // TODO: Match with conversation
    final now = DateTime.now();

    if (index != 0) return [];

    return [
      {
        'id': _uuid.v4(),
        'message_id': '', // TODO: Match with message requiring response
        'conversation_id': conversationId,
        'responder_id': clientId,
        'responder_role': 'CLIENT',
        'action': 'ACCEPT',
        'created_at': now.subtract(Duration(hours: 2)).toIso8601String(),
      },
    ];
  }
}
