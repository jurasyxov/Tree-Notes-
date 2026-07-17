// notes.swift
import Foundation

class Note: Codable {
    var title: String
    var content: String
    var children: [Note]

    init(title: String, content: String = "") {
        self.title = title
        self.content = content
        self.children = []
    }

    func find(_ title: String) -> Note? {
        if self.title == title { return self }
        for child in children {
            if let found = child.find(title) { return found }
        }
        return nil
    }

    func findParent(_ title: String, parent: Note? = nil) -> Note? {
        if self.title == title { return parent }
        for child in children {
            if let found = child.findParent(title, parent: self) { return found }
        }
        return nil
    }

    func delete(_ title: String) -> Bool {
        for (i, child) in children.enumerated() {
            if child.title == title {
                children.remove(at: i)
                return true
            }
            if child.delete(title) { return true }
        }
        return false
    }

    func move(_ title: String, to newParent: Note) -> Bool {
        guard let note = find(title) else { return false }
        guard let parent = findParent(title) else { return false }
        if let idx = parent.children.firstIndex(where: { $0 === note }) {
            parent.children.remove(at: idx)
        }
        newParent.children.append(note)
        return true
    }

    func display(indent: Int = 0) {
        let prefix = children.isEmpty ? "📄" : "📁"
        print(String(repeating: "  ", count: indent) + prefix + " " + title)
        for child in children {
            child.display(indent: indent + 1)
        }
    }

    func search(_ term: String) -> [Note] {
        var results: [Note] = []
        if title.lowercased().contains(term) || content.lowercased().contains(term) {
            results.append(self)
        }
        for child in children {
            results.append(contentsOf: child.search(term))
        }
        return results
    }
}

class App {
    var root: Note
    let filename = "notes.json"

    init() {
        root = Note(title: "Root")
        load()
    }

    func load() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filename) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: filename))
                root = try JSONDecoder().decode(Note.self, from: data)
                return
            } catch {
                // fall through
            }
        }
        root = Note(title: "Root")
    }

    func save(filename: String? = nil) {
        let fname = filename ?? self.filename
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(root)
            try data.write(to: URL(fileURLWithPath: fname))
            print("Saved to \(fname)")
        } catch {
            print("Save failed: \(error)")
        }
    }

    func run() {
        print("🌳 Tree Notes")
        print("Commands: add, delete, move, rename, list, view, search, edit, export, import, save, quit")
        while true {
            print("> ", terminator: "")
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
            let parts = input.split(separator: " ").map(String.init)
            if parts.isEmpty { continue }
            let cmd = parts[0].lowercased()
            switch cmd {
            case "quit":
                save()
                print("Goodbye!")
                return
            case "save":
                save()
            case "add":
                if parts.count < 3 {
                    print("Usage: add <parent> <title>")
                    continue
                }
                let parentTitle = parts[1...parts.count-2].joined(separator: " ")
                let title = parts.last!
                let parent = parentTitle == "root" ? root : root.find(parentTitle)
                guard let parent = parent else {
                    print("Parent '\(parentTitle)' not found.")
                    continue
                }
                parent.children.append(Note(title: title))
                print("Added note '\(title)' under '\(parentTitle)'")
            case "delete":
                if parts.count != 2 {
                    print("Usage: delete <title>")
                    continue
                }
                if root.delete(parts[1]) {
                    print("Deleted '\(parts[1])'")
                } else {
                    print("Note '\(parts[1])' not found.")
                }
            case "move":
                if parts.count < 3 {
                    print("Usage: move <title> <new_parent>")
                    continue
                }
                let moveTitle = parts[1]
                let newParentTitle = parts[2...].joined(separator: " ")
                let note = root.find(moveTitle)
                let newParent = newParentTitle == "root" ? root : root.find(newParentTitle)
                guard let note = note else {
                    print("Note '\(moveTitle)' not found.")
                    continue
                }
                guard let newParent = newParent else {
                    print("Parent '\(newParentTitle)' not found.")
                    continue
                }
                if root.move(moveTitle, to: newParent) {
                    print("Moved '\(moveTitle)' to '\(newParentTitle)'")
                }
            case "rename":
                if parts.count != 3 {
                    print("Usage: rename <old> <new>")
                    continue
                }
                if let note = root.find(parts[1]) {
                    note.title = parts[2]
                    print("Renamed '\(parts[1])' to '\(parts[2])'")
                } else {
                    print("Note '\(parts[1])' not found.")
                }
            case "list":
                if parts.count == 1 {
                    root.display()
                } else {
                    let title = parts[1...].joined(separator: " ")
                    if let note = root.find(title) {
                        note.display()
                    } else {
                        print("Note not found.")
                    }
                }
            case "view":
                if parts.count != 2 {
                    print("Usage: view <title>")
                    continue
                }
                if let note = root.find(parts[1]) {
                    print("Title: \(note.title)")
                    print("Content: \(note.content)")
                } else {
                    print("Note not found.")
                }
            case "edit":
                if parts.count < 3 {
                    print("Usage: edit <title> <content>")
                    continue
                }
                let title = parts[1]
                let content = parts[2...].joined(separator: " ")
                if let note = root.find(title) {
                    note.content = content
                    print("Updated content for '\(title)'")
                } else {
                    print("Note not found.")
                }
            case "search":
                if parts.count != 2 {
                    print("Usage: search <term>")
                    continue
                }
                let results = root.search(parts[1].lowercased())
                if results.isEmpty {
                    print("No results found.")
                } else {
                    print("Found \(results.count) notes:")
                    for r in results {
                        let parent = root.findParent(r.title)
                        print("  \(r.title) (parent: \(parent?.title ?? "root"))")
                    }
                }
            case "export":
                if parts.count != 2 {
                    print("Usage: export <file>")
                    continue
                }
                save(filename: parts[1])
            case "import":
                if parts.count != 2 {
                    print("Usage: import <file>")
                    continue
                }
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: parts[1]))
                    root = try JSONDecoder().decode(Note.self, from: data)
                    print("Imported from \(parts[1])")
                } catch {
                    print("Failed to import.")
                }
            default:
                print("Unknown command.")
            }
        }
    }
}

let app = App()
app.run()
