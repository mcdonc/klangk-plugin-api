import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// A file the workspace wants to render, decoupled from any HTTP client.
///
/// The viewer panel injects the [readText] / [readBytes] loaders so this API
/// stays pure Flutter (no http coupling). [extension] is lowercased and has no
/// leading dot (e.g. `md`, `png`); it is empty when the file has no extension.
class RenderableFile {
  RenderableFile({
    required this.path,
    required this.name,
    required this.extension,
    required this.readText,
    required this.readBytes,
    required this.downloadUrl,
    this.mimeType,
  });

  /// Full path within the workspace (e.g. `docs/readme.md`).
  final String path;

  /// File name including extension (e.g. `readme.md`).
  final String name;

  /// Lowercased extension without the leading dot (e.g. `md`). Empty if none.
  final String extension;

  /// MIME type when known, otherwise null.
  final String? mimeType;

  /// Lazily reads the file's decoded text content.
  final Future<String> Function() readText;

  /// Lazily reads the file's raw bytes.
  final Future<Uint8List> Function() readBytes;

  /// Absolute URL the file can be downloaded from.
  final String downloadUrl;
}

/// Renders a particular kind of file. Contributed by the built-in set or a
/// `FileRendererPlugin`.
///
/// A renderer offers one mode (e.g. View / Edit / Raw). Per-renderer toolbar
/// actions (e.g. image rotate) live inside the widget returned by [build], so
/// this surface stays minimal.
abstract class FileRenderer {
  /// Stable identifier, unique per renderer (e.g. `markdown`, `image`, `raw`).
  String get id;

  /// Label shown in the mode switcher (e.g. `View`, `Edit`, `Raw`).
  String get modeLabel;

  /// Icon shown in the mode switcher.
  IconData get icon;

  /// Higher wins the default slot for a file. Ties keep registration order.
  int get priority;

  /// Whether this renderer can render [file].
  bool canRender(RenderableFile file);

  /// Builds the renderer UI for [file].
  Widget build(BuildContext context, RenderableFile file);
}

/// Registry of [FileRenderer]s. Mirrors `ToolPluginRegistry`: renderers are
/// registered at build time and queried per file.
///
/// Unlike the tool registry this is intentionally NOT a singleton — the
/// workspace owns one instance and passes it down to the viewer panel.
class FileRendererRegistry {
  final List<FileRenderer> _renderers = [];

  /// Registers a single [renderer].
  void register(FileRenderer renderer) {
    _renderers.add(renderer);
  }

  /// Registers every renderer in [renderers], preserving their order.
  void registerAll(Iterable<FileRenderer> renderers) {
    _renderers.addAll(renderers);
  }

  /// All registered renderers, in registration order.
  List<FileRenderer> get renderers => List.unmodifiable(_renderers);

  /// Renderers that can render [file], highest [FileRenderer.priority] first.
  ///
  /// The sort is stable: equal-priority renderers keep their registration
  /// order, so the first-registered builtin wins a tie.
  List<FileRenderer> renderersFor(RenderableFile file) {
    final matches = <(int, FileRenderer)>[];
    for (var i = 0; i < _renderers.length; i++) {
      final renderer = _renderers[i];
      if (renderer.canRender(file)) {
        matches.add((i, renderer));
      }
    }
    matches.sort((a, b) {
      final byPriority = b.$2.priority.compareTo(a.$2.priority);
      return byPriority != 0 ? byPriority : a.$1.compareTo(b.$1);
    });
    return [for (final entry in matches) entry.$2];
  }
}
