import 'dart:async';
import 'package:flutter/widgets.dart';

/// Handler that receives a request map and returns a response string.
typedef ToolHandler = Future<String> Function(Map<String, dynamic> request);

/// Sink a streaming handler calls to emit incremental output deltas.
typedef ToolChunkSink = void Function(String delta);

/// Handler that streams incremental output via [emit] and returns the final
/// response string. Used for long-running actions (e.g. RAG + LLM) so output
/// reaches the caller token-by-token instead of in one final response.
typedef StreamingToolHandler = Future<String> Function(
  Map<String, dynamic> request,
  ToolChunkSink emit,
);

/// A route contributed by a plugin. The host app converts these into
/// framework-specific route objects (e.g. GoRoute).
class PluginRoute {
  /// The path pattern (e.g. '/soliplex-auth-callback').
  final String path;

  /// Builder that creates the widget for this route. Receives the path
  /// parameters and query parameters from the URL.
  final Widget Function(
    BuildContext context,
    Map<String, String> pathParameters,
    Map<String, String> queryParameters,
  ) builder;

  const PluginRoute({required this.path, required this.builder});
}

/// A plugin that provides tool action handlers and optional overlay UI.
abstract class ToolPlugin {
  /// Action names this plugin handles.
  Map<String, ToolHandler> get handlers;

  /// Optional streaming variants of [handlers], keyed by action. When the
  /// caller supports streaming, the registry prefers these and feeds deltas to
  /// the [ToolChunkSink]. Defaults to none, so existing plugins are unaffected.
  Map<String, StreamingToolHandler> get streamingHandlers => const {};

  /// Optional overlay widget to mount in the workspace Stack.
  /// Return null if this plugin has no UI.
  Widget? buildOverlay(BuildContext context) => null;

  /// Optional routes this plugin contributes to the app's router.
  /// The host app collects these from all plugins at startup and adds
  /// them to its route table. Defaults to none.
  List<PluginRoute> get routes => const [];

  /// Called when the plugin is disposed.
  void dispose() {}
}

/// Registry of tool plugins.
class ToolPluginRegistry {
  static final ToolPluginRegistry _instance = ToolPluginRegistry._();
  factory ToolPluginRegistry() => _instance;
  ToolPluginRegistry._();

  final List<ToolPlugin> _plugins = [];
  final Map<String, ToolHandler> _handlers = {};
  final Map<String, StreamingToolHandler> _streamingHandlers = {};

  /// Register a plugin. Call during app startup.
  void register(ToolPlugin plugin) {
    _plugins.add(plugin);
    _handlers.addAll(plugin.handlers);
    _streamingHandlers.addAll(plugin.streamingHandlers);
  }

  /// All registered plugins.
  List<ToolPlugin> get plugins => List.unmodifiable(_plugins);

  /// All routes contributed by registered plugins.
  List<PluginRoute> get routes =>
      _plugins.expand((p) => p.routes).toList(growable: false);

  /// Dispatch an action to the appropriate handler.
  ///
  /// When [onChunk] is provided and the action has a streaming handler, that
  /// handler runs and deltas are emitted through [onChunk]; otherwise the
  /// regular handler runs and only the final string is returned.
  Future<String> dispatch(
    String action,
    Map<String, dynamic> request, {
    ToolChunkSink? onChunk,
  }) async {
    if (onChunk != null) {
      final streaming = _streamingHandlers[action];
      if (streaming != null) {
        return streaming(request, onChunk);
      }
    }
    final handler = _handlers[action];
    if (handler == null) {
      return 'Unknown action: $action';
    }
    return handler(request);
  }

  /// Dispose all plugins and clear the registry.
  void disposeAll() {
    for (final plugin in _plugins) {
      plugin.dispose();
    }
    _plugins.clear();
    _handlers.clear();
    _streamingHandlers.clear();
  }
}
