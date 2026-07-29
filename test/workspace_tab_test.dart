import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klangk_plugin_api/klangk_plugin_api.dart';

/// A tab plugin whose dispose is observable.
class _TestTab extends WorkspaceTabPlugin {
  bool disposed = false;

  @override
  String get title => 'Test';

  @override
  IconData get icon => Icons.star;

  @override
  Widget build(BuildContext context) => const Text('test tab');

  @override
  void dispose() {
    disposed = true;
  }
}

/// A tab plugin that relies on the default no-op dispose.
class _DefaultDisposeTab extends WorkspaceTabPlugin {
  @override
  String get title => 'Default';

  @override
  IconData get icon => Icons.bug_report;

  @override
  Widget build(BuildContext context) => const Text('default dispose tab');
}

/// A tab plugin that exposes a live badge and observes setVisible.
class _BadgedTab extends WorkspaceTabPlugin {
  final ValueNotifier<TabBadge?> _badge = ValueNotifier<TabBadge?>(null);
  bool lastVisible = false;
  int visibleCalls = 0;

  @override
  String get title => 'Badged';

  @override
  IconData get icon => Icons.chat_bubble;

  @override
  Widget build(BuildContext context) => const Text('badged tab');

  @override
  ValueListenable<TabBadge?>? get badge => _badge;

  @override
  void setVisible(bool visible) {
    lastVisible = visible;
    visibleCalls++;
  }

  @override
  void dispose() {
    _badge.dispose();
  }
}

void main() {
  group('WorkspaceTabPlugin', () {
    testWidgets('build renders the tab content widget', (tester) async {
      final tab = _TestTab();
      await tester.pumpWidget(
        MaterialApp(home: Builder(builder: tab.build)),
      );
      expect(find.text('test tab'), findsOneWidget);
    });

    test('exposes title and icon', () {
      final tab = _TestTab();
      expect(tab.title, 'Test');
      expect(tab.icon, Icons.star);
    });

    test('default dispose is a no-op', () {
      // Must not throw; the default impl is an empty body.
      _DefaultDisposeTab().dispose();
    });

    test('default badge is null and setVisible is a no-op', () {
      final tab = _DefaultDisposeTab();
      expect(tab.badge, isNull);
      tab.setVisible(true);
      tab.setVisible(false);
    });

    test('a tab can expose a live badge the host listens to', () {
      final tab = _BadgedTab();
      addTearDown(tab.dispose);
      expect(tab.badge, isNotNull);
      TabBadge? seen;
      tab.badge!.addListener(() => seen = tab.badge!.value);
      tab._badge.value = TabBadge(count: 3, highlight: true);
      expect(seen?.count, 3);
      expect(seen?.highlight, isTrue);
    });

    test('setVisible records host select/deselect', () {
      final tab = _BadgedTab();
      addTearDown(tab.dispose);
      tab.setVisible(true);
      expect(tab.lastVisible, isTrue);
      expect(tab.visibleCalls, 1);
      tab.setVisible(false);
      expect(tab.lastVisible, isFalse);
    });
  });

  group('WorkspaceTabRegistry', () {
    late WorkspaceTabRegistry registry;

    setUp(() {
      // The registry is a singleton shared across tests — start each clean.
      registry = WorkspaceTabRegistry();
      registry.disposeAll();
    });

    test('is a singleton', () {
      expect(
        identical(WorkspaceTabRegistry(), WorkspaceTabRegistry()),
        isTrue,
      );
    });

    test('register adds a tab', () {
      expect(registry.tabs, isEmpty);
      final tab = _TestTab();
      registry.register(tab);
      expect(registry.tabs.length, 1);
      expect(registry.tabs.last, tab);
    });

    test('tabs list is unmodifiable', () {
      expect(() => registry.tabs.add(_TestTab()), throwsUnsupportedError);
    });

    test('disposeAll disposes every tab and clears the registry', () {
      final a = _TestTab();
      final b = _TestTab();
      registry.register(a);
      registry.register(b);
      registry.disposeAll();
      expect(a.disposed, isTrue);
      expect(b.disposed, isTrue);
      expect(registry.tabs, isEmpty);
    });
  });
}
