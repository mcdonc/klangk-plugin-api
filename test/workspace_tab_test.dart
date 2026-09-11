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

/// The canonical #3409 shape: a tab mixing in ChangeNotifier (to own live
/// state), whose dispose is terminal because instances are per page.
class _NotifierTab extends WorkspaceTabPlugin with ChangeNotifier {
  bool disposed = false;

  @override
  String get title => 'Notifier';

  @override
  IconData get icon => Icons.notifications;

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: this, builder: (_, __) => const Text('n'));

  @override
  void dispose() {
    disposed = true;
    super.dispose(); // ChangeNotifier.dispose — terminal, never reused.
  }
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
      registry.clear();
    });

    test('is a singleton', () {
      expect(
        identical(WorkspaceTabRegistry(), WorkspaceTabRegistry()),
        isTrue,
      );
    });

    test('register adds a factory whose createTabs instantiates it', () {
      expect(registry.createTabs(), isEmpty);
      registry.register(_TestTab.new);
      final tabs = registry.createTabs();
      expect(tabs.length, 1);
      expect(tabs.last, isA<_TestTab>());
    });

    test('createTabs list is unmodifiable', () {
      registry.register(_TestTab.new);
      expect(
        () => registry.createTabs().add(_TestTab()),
        throwsUnsupportedError,
      );
    });

    test('createTabs preserves registration order across factories', () {
      // The doc promises "in registration order" — pin it with two
      // distinct factories (a type-permutation bug would flip both pages
      // consistently and dodge the fresh-instance assertions).
      registry
        ..register(_TestTab.new)
        ..register(_BadgedTab.new);
      final tabs = registry.createTabs();
      expect(tabs.first, isA<_TestTab>());
      expect(tabs.last, isA<_BadgedTab>());
    });

    test(
        'createTabs returns FRESH instances per call — a workspace page '
        'owns its tabs and disposes them on close (#3409)', () {
      registry
        ..register(_TestTab.new)
        ..register(_BadgedTab.new);
      final pageOne = registry.createTabs();
      final pageTwo = registry.createTabs();

      // Same classes, same order — but no instance is shared between the
      // two sets: each workspace page gets its own, so a page disposing
      // its tabs can never poison the next page's.
      expect(pageOne.length, pageTwo.length);
      for (var i = 0; i < pageOne.length; i++) {
        expect(identical(pageOne[i], pageTwo[i]), isFalse);
        expect(pageTwo[i].runtimeType, pageOne[i].runtimeType);
      }

      // The page-lifecycle contract end-to-end: dispose page one's tabs
      // (terminal), then page two's build/badge paths still work.
      for (final tab in pageOne) {
        tab.dispose();
      }
      final badged = pageTwo.whereType<_BadgedTab>().single;
      badged._badge.value = const TabBadge(count: 1);
      expect(badged.badge!.value!.count, 1);
      badged.setVisible(true);
      expect(badged.visibleCalls, 1);
      addTearDown(badged.dispose);
    });

    test('a ChangeNotifier tab disposes terminally per page (#3409)', () {
      // The canonical plugin shape the per-page contract protects: a tab
      // mixing in ChangeNotifier (e.g. to own a live badge) calls
      // ChangeNotifier.dispose on workspace close, which is terminal — and
      // that is fine, because the instance is never reused.
      registry.register(_NotifierTab.new);
      final pageOne = registry.createTabs().single as _NotifierTab;
      pageOne.dispose(); // terminal — no assert, no throw.
      expect(pageOne.disposed, isTrue);

      final pageTwo = registry.createTabs().single as _NotifierTab;
      pageTwo.notifyListeners(); // the fresh instance is fully usable.
      expect(pageTwo.disposed, isFalse);
      addTearDown(pageTwo.dispose);
    });

    test('clear drops the registrations without touching instances', () {
      final tab = _TestTab();
      registry.register(() => tab);
      registry.clear();
      expect(registry.createTabs(), isEmpty);
      // The registry owns factories, not instances — clearing must not
      // dispose an instance some page still owns.
      expect(tab.disposed, isFalse);
    });
  });
}
