import 'package:flutter/foundation.dart';

/// Workspace services a feature tab reads from the host, provided through
/// the widget tree (e.g. `context.read<WorkspaceServices>()` via `provider`).
///
/// The host (the frontend) mounts a concrete implementation above the
/// feature-contributed tabs. Feature packages depend only on this abstract
/// interface — not on the host's concrete `WsClient` / `AuthService` — so a
/// feature like `chat` can live in its own package without importing the
/// host app (which would close a package cycle: host → aggregator → feature
/// → host) (#1976).
///
/// Members are nullable where the capability is optional: [chat] is `null`
/// when chat is inactive or the WS surface is unavailable, so a tab can
/// degrade gracefully instead of assuming the service exists.
abstract class WorkspaceServices {
  /// The chat surface (send/receive, presence, history), or `null` when chat
  /// is unavailable in this workspace.
  ChatServices? get chat;

  /// The current user's id — the authenticated identity driving the UI.
  /// Replaces the feature's former `context.read<AuthService>().userId`.
  String get currentUserId;
}

/// Chat capabilities a feature reads from the host's WS client.
///
/// The host's WS client implements this (it is a [Listenable]: presence and
/// history-page changes notify listeners, so a feature widget subscribes via
/// [addListener] / [removeListener] and rebuilds on those changes).
///
/// Messages, presence users, and mention candidates are exchanged as
/// `Map<String, dynamic>` — the raw WS JSON envelopes — so this interface
/// introduces no feature-specific domain types and stays stable as the chat
/// protocol evolves.
abstract class ChatServices implements Listenable {
  /// All chat messages held locally, oldest first.
  List<Map<String, dynamic>> get chatHistory;

  /// Stream of live incoming chat messages.
  Stream<Map<String, dynamic>> get chatMessages;

  /// Stream of older chat-history pages (pagination load-more).
  Stream<Map<String, dynamic>> get chatHistoryPages;

  /// Users currently present in the workspace chat.
  List<Map<String, dynamic>> get presenceUsers;

  /// Candidates for `@`-mention, derived from [presenceUsers].
  List<Map<String, dynamic>> get mentionCandidates;

  /// Send a chat message.
  void sendChatMessage(String text);

  /// Request an older page of chat history before [beforeId].
  void sendChatLoadMore(String beforeId, {int limit = 50});

  /// Delete a chat message by id.
  void sendChatDelete(String messageId);

  /// Abort the in-flight agent run, if any.
  void sendChatAgentAbort();
}
