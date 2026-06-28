import SwiftUI

/// Focused-scene action that toggles the worktree file explorer panel.
///
/// Defined here, in a FileExplorer-owned file, rather than inside the upstream
/// `SidebarCommands.swift` where the sibling sidebar actions live. `FocusedValues`
/// is cross-file extensible, so keeping this out of the upstream file shrinks our
/// local diff there to the unavoidable lines (the menu Button + shortcut lookup)
/// and keeps it merge-clean — see "Minimizing Upstream Merge Conflicts" in AGENTS.md.
private struct ToggleFileExplorerActionKey: FocusedValueKey {
  typealias Value = FocusedAction<Void>
}

extension FocusedValues {
  var toggleFileExplorerAction: FocusedAction<Void>? {
    get { self[ToggleFileExplorerActionKey.self] }
    set { self[ToggleFileExplorerActionKey.self] = newValue }
  }
}
