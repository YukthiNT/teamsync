import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import '../models/task_item.dart';
import '../models/user_presence.dart';

/// Central service that wraps all Supabase interactions:
/// - anonymous auth with a chosen display name
/// - real-time chat message stream + optimistic sends
/// - presence (online/offline) tracking that reacts to app lifecycle
/// - real-time task board stream
///
/// Supabase's `.stream()` API subscribes to Postgres changes over a
/// websocket under the hood — this is the "real-time backend sync" piece.
class SupabaseService with WidgetsBindingObserver {
  final SupabaseClient _client = Supabase.instance.client;

  static const String _messagesTable = 'messages';
  static const String _presenceTable = 'presence';
  static const String _tasksTable = 'tasks';

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Signs the user in anonymously and stores their chosen display name
  /// in the `presence` table so other clients can show it.
  Future<void> signIn(String displayName) async {
    final response = await _client.auth.signInAnonymously();
    final uid = response.user!.id;

    await _client.from(_presenceTable).upsert({
      'user_id': uid,
      'display_name': displayName,
      'is_online': true,
      'last_seen': DateTime.now().toIso8601String(),
    });

    // Start listening to app lifecycle changes so presence updates
    // automatically when the user backgrounds or reopens the app.
    WidgetsBinding.instance.addObserver(this);
  }

  /// Reacts to the app moving to the background/foreground so presence
  /// stays accurate even if the user doesn't explicitly sign out.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = currentUserId;
    if (uid == null) return;

    if (state == AppLifecycleState.resumed) {
      _client.from(_presenceTable).update({
        'is_online': true,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('user_id', uid);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _client.from(_presenceTable).update({
        'is_online': false,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('user_id', uid);
    }
  }

  Future<void> signOut() async {
    final uid = currentUserId;
    if (uid != null) {
      await _client.from(_presenceTable).update({
        'is_online': false,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('user_id', uid);
    }
    WidgetsBinding.instance.removeObserver(this);
    await _client.auth.signOut();
  }

  // ---------------- CHAT ----------------

  /// Live stream of messages, oldest first. Supabase's `.stream()` opens a
  /// realtime websocket subscription and re-emits the full result set
  /// whenever any row in the table changes.
  Stream<List<ChatMessage>> messageStream() {
    return _client
        .from(_messagesTable)
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) => rows.map((row) => ChatMessage.fromMap(row)).toList());
  }

  /// Persists a message. The optimistic bubble is added to the UI
  /// immediately by the provider; this just writes it to Postgres. If it
  /// throws, the provider marks the local bubble as "failed".
  Future<void> sendMessage(String text, String senderName) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not signed in');

    final message = ChatMessage(
      id: '',
      senderId: uid,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
    );

    await _client.from(_messagesTable).insert(message.toInsertMap());
  }

  // ---------------- PRESENCE ----------------

  Stream<List<UserPresence>> presenceStream() {
    return _client
        .from(_presenceTable)
        .stream(primaryKey: ['user_id'])
        .map((rows) => rows.map((row) => UserPresence.fromMap(row)).toList());
  }

  // ---------------- TASK BOARD ----------------

  Stream<List<TaskItem>> taskStream() {
    return _client
        .from(_tasksTable)
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) => rows.map((row) => TaskItem.fromMap(row)).toList());
  }

  Future<void> addTask(String title, String creatorName) async {
    final task = TaskItem(
      id: '',
      title: title,
      createdBy: creatorName,
      status: TaskStatus.todo,
      createdAt: DateTime.now(),
    );
    await _client.from(_tasksTable).insert(task.toInsertMap());
  }

  Future<void> advanceTask(TaskItem task) async {
    await _client
        .from(_tasksTable)
        .update({'status': task.status.next.name}).eq('id', task.id);
  }
}
