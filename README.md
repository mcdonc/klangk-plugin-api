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

## What's Included

- `ToolPlugin` — abstract base class for plugins
- `ToolHandler` — function type for action handlers
- `StreamingToolHandler` — function type for streaming action handlers
- `PluginRoute` — route descriptor for plugin-contributed app routes
- `ToolPluginRegistry` — plugin registration and dispatch
- `baseUrl` — the Klangk backend API base URL (for plugins that need HTTP access)
- `testBaseUrlOverride` — override for testing
