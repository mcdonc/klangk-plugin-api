import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klangk_plugin_api/klangk_plugin_api.dart';

/// Minimal plugin with one handler.
class EchoPlugin extends ToolPlugin {
  bool disposed = false;

  @override
  Map<String, ToolHandler> get handlers => {
        'echo': (request) async => request['message'] as String? ?? '',
      };

  @override
  void dispose() {
    disposed = true;
  }
}

/// Plugin with both regular and streaming handlers.
class StreamPlugin extends ToolPlugin {
  @override
  Map<String, ToolHandler> get handlers => {
        'summarize': (request) async => 'full summary',
      };

  @override
  Map<String, StreamingToolHandler> get streamingHandlers => {
        'summarize': (request, emit) async {
          emit('partial ');
          emit('summary');
          return 'full summary';
        },
      };
}

/// Plugin with no streaming handlers (default).
class SimplePlugin extends ToolPlugin {
  @override
  Map<String, ToolHandler> get handlers => {
        'greet': (request) async => 'hello',
      };
}

void main() {
  late ToolPluginRegistry registry;

  setUp(() {
    registry = ToolPluginRegistry();
    registry.disposeAll();
  });

  tearDown(() {
    registry.disposeAll();
  });

  group('ToolPluginRegistry', () {
    test('register adds plugin and handlers', () {
      final plugin = EchoPlugin();
      registry.register(plugin);
      expect(registry.plugins, contains(plugin));
    });

    test('dispatch calls the correct handler', () async {
      registry.register(EchoPlugin());
      final result =
          await registry.dispatch('echo', {'message': 'hello world'});
      expect(result, 'hello world');
    });

    test('dispatch returns unknown action for unregistered action', () async {
      registry.register(EchoPlugin());
      final result = await registry.dispatch('nope', {});
      expect(result, 'Unknown action: nope');
    });

    test('dispatch without onChunk uses regular handler', () async {
      registry.register(StreamPlugin());
      final result = await registry.dispatch('summarize', {});
      expect(result, 'full summary');
    });

    test('dispatch with onChunk uses streaming handler', () async {
      registry.register(StreamPlugin());
      final chunks = <String>[];
      final result = await registry.dispatch(
        'summarize',
        {},
        onChunk: chunks.add,
      );
      expect(result, 'full summary');
      expect(chunks, ['partial ', 'summary']);
    });

    test('dispatch with onChunk falls back to regular handler when no streaming handler',
        () async {
      registry.register(SimplePlugin());
      final chunks = <String>[];
      final result = await registry.dispatch(
        'greet',
        {},
        onChunk: chunks.add,
      );
      expect(result, 'hello');
      expect(chunks, isEmpty);
    });

    test('disposeAll calls dispose on all plugins', () {
      final p1 = EchoPlugin();
      final p2 = EchoPlugin();
      registry.register(p1);
      registry.register(p2);
      registry.disposeAll();
      expect(p1.disposed, isTrue);
      expect(p2.disposed, isTrue);
    });

    test('disposeAll clears plugins and handlers', () async {
      registry.register(EchoPlugin());
      registry.disposeAll();
      expect(registry.plugins, isEmpty);
      final result = await registry.dispatch('echo', {'message': 'hi'});
      expect(result, 'Unknown action: echo');
    });

    test('multiple plugins register all handlers', () async {
      registry.register(EchoPlugin());
      registry.register(SimplePlugin());
      expect(await registry.dispatch('echo', {'message': 'hi'}), 'hi');
      expect(await registry.dispatch('greet', {}), 'hello');
    });
  });

  group('ToolPlugin defaults', () {
    test('streamingHandlers defaults to empty', () {
      final plugin = SimplePlugin();
      expect(plugin.streamingHandlers, isEmpty);
    });

    testWidgets('buildOverlay defaults to null', (tester) async {
      final plugin = SimplePlugin();
      late BuildContext ctx;
      await tester.pumpWidget(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }));
      expect(plugin.buildOverlay(ctx), isNull);
    });

    test('dispose is a no-op by default', () {
      final plugin = SimplePlugin();
      // Should not throw
      plugin.dispose();
    });
  });

  group('baseUrl', () {
    test('testBaseUrlOverride works', () {
      testBaseUrlOverride = 'http://localhost:8997';
      expect(baseUrl, 'http://localhost:8997');
      testBaseUrlOverride = null;
    });

    test('returns empty string from stub when no override', () {
      testBaseUrlOverride = null;
      expect(baseUrl, '');
    });
  });
}
