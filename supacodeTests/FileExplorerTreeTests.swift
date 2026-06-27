import Foundation
import Testing

@testable import supacode

struct FileExplorerTreeTests {
  private func node(_ path: String, isDirectory: Bool) -> FileExplorerNode {
    let url = URL(fileURLWithPath: path)
    return FileExplorerNode(url: url, name: url.lastPathComponent, isDirectory: isDirectory)
  }

  @Test func sortsDirectoriesBeforeFiles() {
    let nodes = [
      node("/r/zeta.txt", isDirectory: false),
      node("/r/alpha", isDirectory: true),
      node("/r/beta.swift", isDirectory: false),
      node("/r/gamma", isDirectory: true),
    ]
    let sorted = FileExplorerTree.sorted(nodes).map(\.name)
    #expect(sorted == ["alpha", "gamma", "beta.swift", "zeta.txt"])
  }

  @Test func dotfilesSortAheadWithinEachGroup() {
    let nodes = [
      node("/r/src", isDirectory: true),
      node("/r/.github", isDirectory: true),
      node("/r/readme.md", isDirectory: false),
      node("/r/.gitignore", isDirectory: false),
    ]
    let sorted = FileExplorerTree.sorted(nodes).map(\.name)
    // Dirs first (dotfile dir ahead), then files (dotfile file ahead).
    #expect(sorted == [".github", "src", ".gitignore", "readme.md"])
  }

  @Test func sortIsCaseInsensitive() {
    let nodes = [
      node("/r/Banana.txt", isDirectory: false),
      node("/r/apple.txt", isDirectory: false),
      node("/r/cherry.txt", isDirectory: false),
    ]
    let sorted = FileExplorerTree.sorted(nodes).map(\.name)
    #expect(sorted == ["apple.txt", "Banana.txt", "cherry.txt"])
  }

  @Test func flattenDescendsOnlyIntoExpandedDirectories() {
    let root = [
      node("/r/src", isDirectory: true),
      node("/r/docs", isDirectory: true),
      node("/r/readme.md", isDirectory: false),
    ]
    let children: [String: [FileExplorerNode]] = [
      "/r/src": [node("/r/src/main.swift", isDirectory: false), node("/r/src/util", isDirectory: true)],
      "/r/src/util": [node("/r/src/util/helper.swift", isDirectory: false)],
      "/r/docs": [node("/r/docs/guide.md", isDirectory: false)],
    ]
    let expanded: Set<URL> = [URL(fileURLWithPath: "/r/src")]

    let rows = FileExplorerTree.flatten(
      rootChildren: root,
      expanded: expanded,
      childrenProvider: { children[$0.path] ?? [] }
    )

    // Top-level dirs sort alphabetically (docs before src); src is expanded so
    // its children appear (util collapsed), docs stays collapsed.
    #expect(rows.map(\.node.name) == ["docs", "src", "util", "main.swift", "readme.md"])
    #expect(rows.map(\.depth) == [0, 0, 1, 1, 0])

    #expect(rows.first { $0.node.name == "src" }?.isExpanded == true)
    #expect(rows.first { $0.node.name == "util" }?.isExpanded == false)
  }

  @Test func flattenSortsEveryLevel() {
    let root = [node("/r/a", isDirectory: true)]
    let children: [String: [FileExplorerNode]] = [
      "/r/a": [
        node("/r/a/z.txt", isDirectory: false),
        node("/r/a/sub", isDirectory: true),
        node("/r/a/.env", isDirectory: false),
      ]
    ]
    let rows = FileExplorerTree.flatten(
      rootChildren: root,
      expanded: [URL(fileURLWithPath: "/r/a")],
      childrenProvider: { children[$0.path] ?? [] }
    )
    // a, then sorted children: sub (dir), .env (dotfile), z.txt.
    #expect(rows.map(\.node.name) == ["a", "sub", ".env", "z.txt"])
  }
}
