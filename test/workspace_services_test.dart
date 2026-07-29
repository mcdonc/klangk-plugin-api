import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klangk_plugin_api/klangk_plugin_api.dart';

/// A concrete [ChatServices] capturing send calls, backed by a
/// [ChangeNotifier] so addListener/removeListener behave like the host's.
class _FakeChat extends ChangeNotifier implements ChatServices {
  final List<String> sent = [];
  final List<String> deleted = [];
  final List<String> loadedMore = [];
  bool aborted = false;
  final _msgController = StreamController<Map<String, dynamic>>();

  @override
  List<Map<String, dynamic>> chatHistory = [];
  @override
  List<Map<String, dynamic>> presenceUsers = [];
  @override
  Stream<Map<String, dynamic>> get chatMessages => _msgController.stream;
  @override
  Stream<Map<String, dynamic>> chatHistoryPages = const Stream.empty();

  @override
  List<Map<String, dynamic>> get mentionCandidates => presenceUsers;

  @override
  void sendChatMessage(String text) => sent.add(text);
  @override
  void sendChatLoadMore(String beforeId, {int limit = 50}) =>
      loadedMore.add('$beforeId:$limit');
  @override
  void sendChatDelete(String messageId) => deleted.add(messageId);
  @override
  void sendChatAgentAbort() => aborted = true;

  @override
  void dispose() {
    _msgController.close();
    super.dispose();
  }
}

class _FakeServices implements WorkspaceServices {
  _FakeServices(this.chat, this.currentUserId);
  @override
  final ChatServices? chat;
  @override
  final String currentUserId;
}

void main() {
  group('ChatServices', () {
    test('is a Listenable (so a feature widget can subscribe to changes)', () {
      final chat = _FakeChat();
      addTearDown(chat.dispose);
      expect(chat, isA<Listenable>());
    });

    test('send methods capture calls with default limit', () {
      final chat = _FakeChat();
      addTearDown(chat.dispose);
      chat.sendChatMessage('hi');
      chat.sendChatDelete('m1');
      chat.sendChatLoadMore('oldest');
      chat.sendChatAgentAbort();
      expect(chat.sent, ['hi']);
      expect(chat.deleted, ['m1']);
      expect(chat.loadedMore, ['oldest:50']);
      expect(chat.aborted, isTrue);
    });

    test('listeners fire on notifyListeners', () {
      final chat = _FakeChat();
      addTearDown(chat.dispose);
      var calls = 0;
      chat.addListener(() => calls++);
      chat.notifyListeners();
      chat.notifyListeners();
      expect(calls, 2);
    });
  });

  group('WorkspaceServices', () {
    test('exposes the chat surface and current user id', () {
      final chat = _FakeChat();
      addTearDown(chat.dispose);
      final services = _FakeServices(chat, 'user-42');
      expect(services.chat, same(chat));
      expect(services.currentUserId, 'user-42');
    });

    test('chat is null when chat is unavailable', () {
      final services = _FakeServices(null, 'user-42');
      expect(services.chat, isNull);
    });
  });
}
