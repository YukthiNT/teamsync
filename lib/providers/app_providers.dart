import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/task_item.dart';
import '../models/user_presence.dart';
import '../services/supabase_service.dart';

/// Single shared instance of the Supabase service used across the app.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Stores the signed-in user's chosen display name.
final displayNameProvider = StateProvider<String?>((ref) => null);

/// Raw real-time stream of messages straight from Supabase.
final remoteMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  return ref.watch(supabaseServiceProvider).messageStream();
});

/// Live presence list (who's online).
final presenceProvider = StreamProvider<List<UserPresence>>((ref) {
  return ref.watch(supabaseServiceProvider).presenceStream();
});

/// Live task board stream.
final tasksProvider = StreamProvider<List<TaskItem>>((ref) {
  return ref.watch(supabaseServiceProvider).taskStream();
});

/// Manages the optimistic-UI chat list: merges Supabase's confirmed
/// messages with any locally-sent messages that haven't round-tripped yet.
/// This is the core "feels instant" trick behind real-time chat apps.
class ChatController extends StateNotifier<List<ChatMessage>> {
  final SupabaseService _service;
  final Ref _ref;

  ChatController(this._service, this._ref) : super([]) {
    // Whenever Supabase's real list updates, reconcile it with any
    // pending local (optimistic) messages still in flight.
    _ref.listen<AsyncValue<List<ChatMessage>>>(remoteMessagesProvider,
        (previous, next) {
      next.whenData((remoteMessages) {
        final pendingLocal = state
            .where((m) => m.status == MessageStatus.sending)
            .toList();
        state = [...remoteMessages, ...pendingLocal];
      });
    });
  }

  /// Adds a message to the UI immediately (optimistic), then persists it.
  /// If the write fails, the bubble flips to "failed" so the user can retry.
  Future<void> sendMessage(String text, String senderName) async {
    final tempId = const Uuid().v4();
    final optimisticMessage = ChatMessage(
      id: tempId,
      senderId: _service.currentUserId ?? 'me',
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    state = [...state, optimisticMessage];

    try {
      await _service.sendMessage(text, senderName);
      // Once Supabase's realtime stream fires, the listener above
      // replaces this optimistic bubble with the confirmed one.
    } catch (_) {
      state = [
        for (final m in state)
          if (m.id == tempId) m.copyWith(status: MessageStatus.failed) else m,
      ];
    }
  }

  /// Removes a failed message so the user can re-type and resend it.
  void dismissFailed(String tempId) {
    state = state.where((m) => m.id != tempId).toList();
  }
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, List<ChatMessage>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return ChatController(service, ref);
});
