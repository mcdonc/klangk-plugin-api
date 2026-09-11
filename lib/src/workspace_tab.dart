import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A tab's strip-header badge (e.g. an unread count), exposed to the host
/// via [WorkspaceTabPlugin.badge] as a [ValueListenable]. The host renders
/// no badge when [count] is 0.
class TabBadge {
  /// The count to display in the badge (e.g. unread messages).
  /// The host renders no badge when this is 0.
  final int count;

  /// Whether to highlight the badge (e.g. an @-mention / urgent).
  /// Default false.
  final bool highlight;

  const TabBadge({required this.count, this.highlight = false});
}

/// A plugin that contributes a workspace tab.
///
/// A feature declares a tab by extending this class and providing a [title],
/// [icon], and [build] that returns the tab's content widget. Deliberately
/// separate from `ToolPlugin` (which is tool-action-specific): a feature
/// package may implement `ToolPlugin`, [WorkspaceTabPlugin], or both — e.g. a
/// `chat` feature contributes both a chat tab and agent tool handlers.
///
/// Tabs mount in the workspace tab strip only when their feature is active
/// (filtered by `KLANGKD_FEATURES_ENABLE` at boot, alongside `ToolPlugin`
/// registration). A feature shipped but inactive never registers its tab, so
/// its tab is absent from the strip — its Dart is in the monolithic bundle
/// but inert.
///
/// ## Lifecycle
///
/// Tab instances are per-workspace-page (#3409). The host registers a
/// factory once at app boot (`WorkspaceTabRegistry.register`), and each
/// workspace page creates a fresh set of instances via
/// `WorkspaceTabRegistry.createTabs()`, builds them, and disposes them when
/// the page closes. A disposed instance is never rebuilt or reused, so
/// [dispose] is terminal: the tab may freely mix in `ChangeNotifier` and
/// release everything it owns. Per-workspace state belongs on the instance
/// (each page gets its own), never in statics.
///
/// This differs from `ToolPlugin`, whose registry holds the app-lifetime
/// instances themselves.
abstract class WorkspaceTabPlugin {
  /// Tab title shown in the tab strip.
  String get title;

  /// Tab icon shown in the tab strip.
  IconData get icon;

  /// Builds the tab's content widget, mounted in the workspace content pane.
  Widget build(BuildContext context);

  /// Optional badge for the tab strip header (e.g. unread chat count). The
  /// host listens to this [ValueListenable] and re-renders the badge when the
  /// value changes. `null` (default) — the tab shows no badge.
  ///
  /// Exposed as a [ValueListenable] (not a plain getter) so the host can
  /// react to changes without the tab being a [Listenable] itself.
  ValueListenable<TabBadge?>? get badge => null;

  /// Called by the host when this tab becomes the selected/visible tab
  /// ([visible] == true) or is hidden (false). Override to react — e.g. mark
  /// messages read on view, or focus the input. Default no-op.
  void setVisible(bool visible) {}

  /// Called when the workspace page that created this tab closes (#3409).
  /// The instance is per-workspace-page: the host never reuses it after
  /// this call — the next workspace page builds from a fresh instance. So
  /// dispose is terminal; override it to release everything the tab owns
  /// (calling `ChangeNotifier.dispose` from a mixin is safe).
  void dispose() {}
}

/// Registry of [WorkspaceTabPlugin] factories. Mirrors `ToolPluginRegistry`
/// in being a boot-time singleton (there is one app-wide set of active
/// feature tabs, registered once in `main()`), but it holds factories, not
/// instances: each workspace page creates its own fresh tab instances via
/// [createTabs] and disposes them when it closes (#3409), keeping
/// `WorkspaceTabPlugin.dispose` terminal. `ToolPluginRegistry`, by contrast,
/// holds the app-lifetime instances themselves.
class WorkspaceTabRegistry {
  static final WorkspaceTabRegistry _instance = WorkspaceTabRegistry._();
  factory WorkspaceTabRegistry() => _instance;
  WorkspaceTabRegistry._();

  final List<WorkspaceTabPlugin Function()> _factories = [];

  /// Register a tab factory. Call during app startup, after the
  /// active-feature filter has resolved which features to mount. The
  /// factory must not throw — `createTabs()` gives the created instances
  /// no owner, so a factory failing mid-list would leak the ones already
  /// created with no page to dispose them.
  void register(WorkspaceTabPlugin Function() create) {
    _factories.add(create);
  }

  /// Create a fresh instance of every registered tab, in registration
  /// order. Each workspace page calls this once when it mounts and owns
  /// the returned instances for the page's lifetime — the page disposes
  /// them when it closes, and the next page creates its own fresh set
  /// from the same factories.
  List<WorkspaceTabPlugin> createTabs() =>
      List.unmodifiable([for (final create in _factories) create()]);

  /// Drop all registrations. The registry owns factories, not instances,
  /// so this disposes nothing — the workspace pages that called
  /// [createTabs] own (and dispose) the instances they created. Tests use
  /// this to reset the process-global singleton between cases.
  void clear() {
    _factories.clear();
  }
}
