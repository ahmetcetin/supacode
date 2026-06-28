import Foundation
import Testing

@testable import supacode

struct FileViewerFileTypeTests {
  @Test func binarySniffDetectsNulByte() {
    let text = Data("plain text file\nsecond line".utf8)
    #expect(!FileViewerFileType.isProbablyBinary(text))

    var binary = Data("header".utf8)
    binary.append(0)
    binary.append(contentsOf: [0x01, 0x02])
    #expect(FileViewerFileType.isProbablyBinary(binary))
  }

  @Test func markdownByExtension() {
    #expect(FileViewerFileType.isMarkdown(url: URL(filePath: "/r/notes.md"), sample: ""))
    #expect(FileViewerFileType.isMarkdown(url: URL(filePath: "/r/guide.markdown"), sample: ""))
    #expect(!FileViewerFileType.isMarkdown(url: URL(filePath: "/r/main.swift"), sample: "import Foundation"))
  }

  @Test func markdownByWellKnownFilename() {
    // Extension-less files Warp also renders as markdown.
    #expect(FileViewerFileType.isMarkdown(url: URL(filePath: "/r/README"), sample: "anything"))
    #expect(FileViewerFileType.isMarkdown(url: URL(filePath: "/r/LICENSE"), sample: "Copyright"))
    #expect(!FileViewerFileType.isMarkdown(url: URL(filePath: "/r/Makefile"), sample: "all:\n\tbuild"))
  }

  @Test func markdownByContentSniff() {
    #expect(FileViewerFileType.isMarkdown(url: URL(filePath: "/r/notes.txt"), sample: "# Title\n\nbody"))
    #expect(FileViewerFileType.isMarkdown(url: URL(filePath: "/r/notes.txt"), sample: "```\ncode\n```"))
    #expect(
      !FileViewerFileType.isMarkdown(url: URL(filePath: "/r/notes.txt"), sample: "just some prose without markers"))
    // A `#` that isn't an ATX heading (no space) must not count.
    #expect(!FileViewerFileType.isMarkdown(url: URL(filePath: "/r/notes.txt"), sample: "#notaheading"))
  }

  @Test func highlightrLanguageMapping() {
    #expect(FileViewerFileType.highlightrLanguage(for: URL(filePath: "/r/a.swift")) == "swift")
    #expect(FileViewerFileType.highlightrLanguage(for: URL(filePath: "/r/a.tsx")) == "typescript")
    #expect(FileViewerFileType.highlightrLanguage(for: URL(filePath: "/r/a.py")) == "python")
    #expect(FileViewerFileType.highlightrLanguage(for: URL(filePath: "/r/Dockerfile")) == "dockerfile")
    #expect(FileViewerFileType.highlightrLanguage(for: URL(filePath: "/r/Makefile")) == "makefile")
    // Unknown extension → nil so Highlightr auto-detects.
    #expect(FileViewerFileType.highlightrLanguage(for: URL(filePath: "/r/a.unknownext")) == nil)
  }
}
