# klangk_plugin_api

Dart API package for [Klangk](https://github.com/mcdonc/klangk) plugins.

## Usage

Add this package as a dependency in your plugin's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  klangk_plugin_api:
    git:
      url: https://github.com/mcdonc/klangk-plugin-api.git
```

Then import it in your plugin:

```dart
import 'package:klangk_plugin_api/klangk_plugin_api.dart';

class MyPlugin extends ToolPlugin {
  @override
  Map<String, ToolHandler> get handlers => {
    'my_action': _handle,
  };

  Future<String> _handle(Map<String, dynamic> request) async {
    return 'Hello from my plugin!';
  }

  @override
  List<PluginRoute> get routes => [
    PluginRoute(
      path: '/my-callback',
      builder: (context, pathParams, queryParams) {
        return Text('Token: ${queryParams['token']}');
      },
    ),
  ];
}
```

## Contributing a workspace tab

A feature can contribute a workspace tab (mounted in the workspace tab strip)
by extending `WorkspaceTabPlugin` instead of (or in addition to) `ToolPlugin`:

```dart
import 'package:klangk_plugin_api/klangk_plugin_api.dart';

class MyTab extends WorkspaceTabPlugin {
  @override
  String get title => 'My Tab';

  @override
  IconData get icon => Icons.star;

  @override
  Widget build(BuildContext context) => const Center(child: Text('hello'));
}
```

A feature package may implement `ToolPlugin`, `WorkspaceTabPlugin`, or both —
e.g. a `chat` feature contributes both a chat tab and agent tool handlers.
The host app registers active tabs into `WorkspaceTabRegistry` at boot and
mounts them in the workspace shell; a feature shipped but inactive (filtered
out by `KLANGKD_FEATURES_ENABLE`) never registers its tab.

## What's Included

- `ToolPlugin` — abstract base class for plugins
- `ToolHandler` — function type for action handlers
- `StreamingToolHandler` — function type for streaming action handlers
- `PluginRoute` — route descriptor for plugin-contributed app routes
- `ToolPluginRegistry` — plugin registration and dispatch
- `WorkspaceTabPlugin` — abstract base class for a feature-contributed workspace tab
- `WorkspaceTabRegistry` — registration for feature-contributed workspace tabs
- `FileRenderer` / `FileRendererRegistry` / `FileRendererPlugin` — file-viewer abstraction
- `baseUrl` — the Klangk backend API base URL (for plugins that need HTTP access)
- `testBaseUrlOverride` — override for testing
