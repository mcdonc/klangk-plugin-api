import 'open_url_stub.dart'
    if (dart.library.js_interop) 'open_url_web.dart';

/// Override for testing — set to capture/no-op `openUrl` in VM tests.
///
/// Mirrors `testBaseUrlOverride` in `backend_url.dart`: a non-null value
/// short-circuits DOM access so tests don't touch the browser. Restore to
/// `null` (or wrap in addTearDown) when done.
void Function(String)? testOpenUrlOverride;

/// Open [url] in a new browser tab.
///
/// No-op on non-web platforms (VM/desktop). Feature packages call this
/// instead of the host's web-helpers so they don't import the host package
/// (#1976). Set [testOpenUrlOverride] to observe calls in tests.
void openUrl(String url) {
  final override = testOpenUrlOverride;
  if (override != null) {
    override(url);
    return;
  }
  openUrlInBrowser(url);
}
