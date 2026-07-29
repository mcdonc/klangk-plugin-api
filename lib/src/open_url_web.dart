import 'package:web/web.dart' as web;

/// Web implementation — opens the URL in a new browser tab via `window.open`.
void openUrlInBrowser(String url) {
  web.window.open(url, '_blank');
}
