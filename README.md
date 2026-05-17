# bark_plugin_api

Dart API package for [Bark](https://github.com/mcdonc/bark) plugins.

## Usage

Add this package as a dependency in your plugin's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  bark_plugin_api:
    git:
      url: https://github.com/mcdonc/bark-plugin-api.git
```

Then import it in your plugin:

```dart
import 'package:bark_plugin_api/bark_plugin_api.dart';

class MyPlugin extends ToolPlugin {
  @override
  Map<String, ToolHandler> get handlers => {
    'my_action': _handle,
  };

  Future<String> _handle(Map<String, dynamic> request) async {
    return 'Hello from my plugin!';
  }
}
```

## What's Included

- `ToolPlugin` — abstract base class for plugins
- `ToolHandler` — function type for action handlers
- `ToolPluginRegistry` — plugin registration and dispatch
- `baseUrl` — the Bark backend API base URL (for plugins that need HTTP access)
- `testBaseUrlOverride` — override for testing
