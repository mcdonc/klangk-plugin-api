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
