import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
/// A tab's strip-header badge (e.g. an unread count), exposed via
/// [WorkspaceTabPlugin.badge] as a [ValueListenable] the host listens to.
class TabBadge {
  /// The count to display in the badge (e.g. unread messages).
  /// The host renders no badge when this is 0.
  final int count;

  /// Whether to highlight the badge (e.g. an @-mention / urgent).
  /// Default false.
  final bool highlight;

  const TabBadge({required this.count, this.highlight = false});
}

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

  /// Called when the tab plugin is disposed (the workspace closes).
  /// Defaults to doing nothing; override to release resources.
  void dispose() {}
}

/// Registry of [WorkspaceTabPlugin]s. Mirrors `ToolPluginRegistry`: tabs are
/// registered at app boot (only active features) and queried by the workspace
/// shell to mount feature-contributed tabs in the tab strip.
///
/// Like `ToolPluginRegistry` this is a singleton — there is one app-wide set
/// of feature tabs, registered once in `main()` and read by each workspace
/// page.
class WorkspaceTabRegistry {
  static final WorkspaceTabRegistry _instance = WorkspaceTabRegistry._();
  factory WorkspaceTabRegistry() => _instance;
  WorkspaceTabRegistry._();

  final List<WorkspaceTabPlugin> _tabs = [];

  /// Register a tab plugin. Call during app startup, after the active-feature
  /// filter has resolved which features to mount.
  void register(WorkspaceTabPlugin tab) {
    _tabs.add(tab);
  }

  /// All registered tab plugins, in registration order.
  List<WorkspaceTabPlugin> get tabs => List.unmodifiable(_tabs);

  /// Dispose all tab plugins and clear the registry.
  void disposeAll() {
    for (final tab in _tabs) {
      tab.dispose();
    }
    _tabs.clear();
  }
}
