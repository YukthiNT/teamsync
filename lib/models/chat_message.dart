/// Status of a message as it moves through the optimistic-UI lifecycle.
enum MessageStatus { sending, sent, failed }

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  /// Builds a message from a Supabase/Postgres row (a plain Map).
  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'].toString(),
      senderId: data['sender_id'] ?? '',
      senderName: data['sender_name'] ?? 'Unknown',
      text: data['text'] ?? '',
      timestamp: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  /// Converts this message into a map ready to insert into Supabase.
  /// `created_at` is left out — the database column defaults to now().
  Map<String, dynamic> toInsertMap() {
    return {
      'sender_id': senderId,
      'sender_name': senderName,
      'text': text,
    };
  }

  /// Returns a copy of this message with a different status.
  /// Used to flip a locally-added "sending" bubble to "sent" or "failed".
  ChatMessage copyWith({MessageStatus? status}) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }
}
