/// API package for Klangk plugins.
///
/// Provides the [ToolPlugin] base class for writing plugins, the
/// [FileRenderer] / [FileRendererRegistry] / [FileRendererPlugin] file-viewer
/// abstraction, [WorkspaceTabPlugin] / [WorkspaceTabRegistry] for contributing
/// workspace tabs, [WorkspaceServices] / [ChatServices] for reading workspace
/// runtime services (chat surface, identity) from the host, and [baseUrl] for
/// accessing the Klangk backend API.
library klangk_plugin_api;

export 'src/tool_plugin.dart';
export 'src/backend_url.dart';
export 'src/file_renderer.dart';
export 'src/file_renderer_plugin.dart';
export 'src/workspace_tab.dart';
export 'src/workspace_services.dart';
