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

  /// Dispose all plugins.
  void disposeAll() {
    for (final plugin in _plugins) {
      plugin.dispose();
    }
  }
}
