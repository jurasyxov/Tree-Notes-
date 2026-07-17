# notes.py
import json
import os

class Note:
    def __init__(self, title, content=""):
        self.title = title
        self.content = content
        self.children = []

    def to_dict(self):
        return {
            "title": self.title,
            "content": self.content,
            "children": [c.to_dict() for c in self.children]
        }

    @classmethod
    def from_dict(cls, data):
        note = cls(data["title"], data.get("content", ""))
        note.children = [cls.from_dict(c) for c in data.get("children", [])]
        return note

    def find(self, title):
        if self.title == title:
            return self
        for child in self.children:
            result = child.find(title)
            if result:
                return result
        return None

    def find_parent(self, title, parent=None):
        if self.title == title:
            return parent
        for child in self.children:
            result = child.find_parent(title, self)
            if result is not None:
                return result
        return None

    def delete(self, title):
        for i, child in enumerate(self.children):
            if child.title == title:
                del self.children[i]
                return True
            if child.delete(title):
                return True
        return False

    def move(self, title, new_parent):
        note = self.find(title)
        if not note:
            return False
        parent = self.find_parent(title)
        if not parent:
            return False
        parent.children.remove(note)
        new_parent.children.append(note)
        return True

    def display(self, indent=0, prefix="📁"):
        print("  " * indent + f"{prefix} {self.title}")
        for child in self.children:
            child.display(indent + 1, "📄" if not child.children else "📁")

    def search(self, term):
        results = []
        if term.lower() in self.title.lower() or term.lower() in self.content.lower():
            results.append(self)
        for child in self.children:
            results.extend(child.search(term))
        return results

class NotesApp:
    def __init__(self):
        self.root = None
        self.filename = "notes.json"
        self.load()

    def load(self):
        if os.path.exists(self.filename):
            try:
                with open(self.filename, 'r') as f:
                    data = json.load(f)
                self.root = Note.from_dict(data)
            except:
                self.root = Note("Root")
        else:
            self.root = Note("Root")

    def save(self, filename=None):
        if not filename:
            filename = self.filename
        with open(filename, 'w') as f:
            json.dump(self.root.to_dict(), f, indent=2)
        print(f"Saved to {filename}")

    def run(self):
        print("🌳 Tree Notes")
        print("Commands: add, delete, move, rename, list, view, search, edit, export, import, save, quit")
        while True:
            try:
                cmd = input("> ").strip().split()
                if not cmd:
                    continue
                command = cmd[0].lower()
                if command == "quit":
                    self.save()
                    print("Goodbye!")
                    break
                elif command == "save":
                    self.save()
                elif command == "add" and len(cmd) >= 3:
                    parent_title = " ".join(cmd[1:-1])
                    title = cmd[-1]
                    parent = self.root.find(parent_title) if parent_title != "root" else self.root
                    if parent:
                        note = Note(title)
                        parent.children.append(note)
                        print(f"Added note '{title}' under '{parent_title}'")
                    else:
                        print(f"Parent '{parent_title}' not found.")
                elif command == "delete" and len(cmd) == 2:
                    title = cmd[1]
                    if self.root.delete(title):
                        print(f"Deleted '{title}'")
                    else:
                        print(f"Note '{title}' not found.")
                elif command == "move" and len(cmd) >= 3:
                    title = cmd[1]
                    new_parent_title = " ".join(cmd[2:])
                    note = self.root.find(title)
                    new_parent = self.root.find(new_parent_title) if new_parent_title != "root" else self.root
                    if not note:
                        print(f"Note '{title}' not found.")
                    elif not new_parent:
                        print(f"Parent '{new_parent_title}' not found.")
                    else:
                        old_parent = self.root.find_parent(title)
                        if old_parent:
                            old_parent.children.remove(note)
                            new_parent.children.append(note)
                            print(f"Moved '{title}' to '{new_parent_title}'")
                elif command == "rename" and len(cmd) == 3:
                    old, new = cmd[1], cmd[2]
                    note = self.root.find(old)
                    if note:
                        note.title = new
                        print(f"Renamed '{old}' to '{new}'")
                    else:
                        print(f"Note '{old}' not found.")
                elif command == "list":
                    if len(cmd) == 1:
                        self.root.display()
                    else:
                        note = self.root.find(" ".join(cmd[1:]))
                        if note:
                            note.display()
                        else:
                            print("Note not found.")
                elif command == "view" and len(cmd) == 2:
                    note = self.root.find(cmd[1])
                    if note:
                        print(f"Title: {note.title}")
                        print(f"Content: {note.content}")
                    else:
                        print("Note not found.")
                elif command == "edit" and len(cmd) >= 3:
                    title = cmd[1]
                    content = " ".join(cmd[2:])
                    note = self.root.find(title)
                    if note:
                        note.content = content
                        print(f"Updated content for '{title}'")
                    else:
                        print("Note not found.")
                elif command == "search" and len(cmd) == 2:
                    term = cmd[1]
                    results = self.root.search(term)
                    if results:
                        print(f"Found {len(results)} notes:")
                        for r in results:
                            parent = self.root.find_parent(r.title)
                            parent_title = parent.title if parent else "root"
                            print(f"  {r.title} (parent: {parent_title})")
                    else:
                        print("No results found.")
                elif command == "export" and len(cmd) == 2:
                    self.save(cmd[1])
                elif command == "import" and len(cmd) == 2:
                    try:
                        with open(cmd[1], 'r') as f:
                            data = json.load(f)
                        self.root = Note.from_dict(data)
                        print(f"Imported from {cmd[1]}")
                    except:
                        print("Failed to import.")
                else:
                    print("Unknown command or invalid arguments.")
            except KeyboardInterrupt:
                print("\nUse 'quit' to exit.")
            except Exception as e:
                print(f"Error: {e}")

if __name__ == "__main__":
    app = NotesApp()
    app.run()
