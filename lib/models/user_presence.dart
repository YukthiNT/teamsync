class UserPresence {
  final String userId;
  final String displayName;
  final bool isOnline;
  final DateTime lastSeen;

  UserPresence({
    required this.userId,
    required this.displayName,
    required this.isOnline,
    required this.lastSeen,
  });

  factory UserPresence.fromMap(Map<String, dynamic> data) {
    return UserPresence(
      userId: data['user_id'].toString(),
      displayName: data['display_name'] ?? 'Unknown',
      isOnline: data['is_online'] ?? false,
      lastSeen: DateTime.tryParse(data['last_seen'] ?? '') ?? DateTime.now(),
    );
  }
}
