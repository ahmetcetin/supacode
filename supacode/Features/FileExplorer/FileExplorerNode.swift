import Foundation

/// A single entry (file or directory) in the worktree file explorer tree.
///
/// Pure value type: it carries no expansion or selection state, only the
/// on-disk identity. Expansion lives in `FileExplorerModel`; the visible,
/// flattened list is `FileExplorerRow`.
nonisolated struct FileExplorerNode: Identifiable, Hashable, Sendable {
  let url: URL
  let name: String
  let isDirectory: Bool

  var id: URL { url }

  /// Dotfiles (`.gitignore`, `.env`, …) sort ahead of their siblings within the
  /// same kind, matching the file-tree convention used by editors and Warp.
  var isHidden: Bool { name.hasPrefix(".") }
}

/// A flattened, depth-tagged row ready for rendering. The tree is rendered as a
/// flat `List` of these so only expanded branches contribute rows (bounded cost,
/// no recursion in the view body).
nonisolated struct FileExplorerRow: Identifiable, Hashable, Sendable {
  let node: FileExplorerNode
  let depth: Int
  let isExpanded: Bool

  var id: URL { node.url }
}

/// Pure ordering + flattening for the explorer tree. Kept free of FileManager so
/// it is unit-testable with an in-memory directory map.
nonisolated enum FileExplorerTree {
  /// Directories before files; within each kind, dotfiles first; then a
  /// case-insensitive, locale-aware compare. Mirrors Warp's sort order.
  static func sorted(_ nodes: [FileExplorerNode]) -> [FileExplorerNode] {
    nodes.sorted { lhs, rhs in
      if lhs.isDirectory != rhs.isDirectory {
        return lhs.isDirectory && !rhs.isDirectory
      }
      if lhs.isHidden != rhs.isHidden {
        return lhs.isHidden && !rhs.isHidden
      }
      return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
  }

  /// Depth-first flatten of `rootChildren`, descending into a directory only
  /// when its URL is in `expanded`. `childrenProvider` returns the (unsorted)
  /// children of a directory; this function sorts at every level.
  static func flatten(
    rootChildren: [FileExplorerNode],
    expanded: Set<URL>,
    childrenProvider: (URL) -> [FileExplorerNode]
  ) -> [FileExplorerRow] {
    var rows: [FileExplorerRow] = []
    func visit(_ nodes: [FileExplorerNode], depth: Int) {
      for node in sorted(nodes) {
        let isExpanded = node.isDirectory && expanded.contains(node.url)
        rows.append(FileExplorerRow(node: node, depth: depth, isExpanded: isExpanded))
        if isExpanded {
          visit(childrenProvider(node.url), depth: depth + 1)
        }
      }
    }
    visit(rootChildren, depth: 0)
    return rows
  }
}
