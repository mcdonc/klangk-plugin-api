import 'file_renderer.dart';

/// A plugin that contributes [FileRenderer]s to the workspace file viewer.
///
/// Deliberately separate from `ToolPlugin` (which is tool-action-specific). A
/// plugin package may implement `ToolPlugin`, [FileRendererPlugin], or both.
abstract class FileRendererPlugin {
  /// The renderers this plugin contributes.
  List<FileRenderer> get fileRenderers;
}
