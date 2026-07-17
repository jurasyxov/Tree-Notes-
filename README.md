🌳 Tree Notes – Multi‑Language Edition
A hierarchical tree‑based note‑taking application that organises your thoughts, ideas, and tasks in a structured outline.
Each note can have unlimited children, making it perfect for brainstorming, project planning, and knowledge management.
Built in 7 programming languages – each with a consistent feature set and interactive CLI.

✨ Features
Hierarchical tree structure – each note can contain child notes, creating an infinite outline.

CRUD operations – create, read, update, and delete notes.

Move notes – re‑parent a note to any other node in the tree.

Search – find notes by title or content (recursive).

Export/Import – save your entire note tree to a JSON file and load it later.

View tree – display the full structure with indentation (ASCII tree).

Expand/collapse – view a specific branch or the entire tree.

Persistent storage – automatically saves to a local JSON file (notes.json).

Interactive CLI – intuitive commands with help.

🗂 Languages & Files
Language	File
Python	notes.py
Go	notes.go
JavaScript (Node)	notes.js
C#	Notes.cs
Java	Notes.java
Ruby	notes.rb
Swift	notes.swift
🚀 How to Run
Each file is standalone – run it with the appropriate interpreter/compiler.

Language	Command
Python	python notes.py
Go	go run notes.go
JavaScript	node notes.js
C#	dotnet run (or csc Notes.cs && Notes.exe)
Java	javac Notes.java && java Notes
Ruby	ruby notes.rb
Swift	swift notes.swift
📊 Example Session
text
🌳 Tree Notes
Commands: add, delete, move, rename, list, view, search, export, import, save, quit

> add root My Project
Added note "My Project" as root

> add My Project "Phase 1"
Added note "Phase 1" under "My Project"

> add My Project "Phase 2"
Added note "Phase 2" under "My Project"

> add "Phase 1" "Research"
Added note "Research" under "Phase 1"

> list
📁 My Project
  📁 Phase 1
    📄 Research
  📁 Phase 2

> search research
Found: Research (parent: Phase 1)
🔧 Commands
Command	Description
add <parent> <title>	Add a new note under parent
delete <title>	Delete a note by title
move <title> <new_parent>	Move a note to a new parent
rename <old> <new>	Rename a note
list	Show the full tree
list <title>	Show subtree from a note
view <title>	View the content of a note
edit <title> <content>	Set content of a note
search <term>	Search titles and content
export <file>	Export tree to JSON
import <file>	Import tree from JSON
save	Save to default file (notes.json)
quit	Exit the application
📜 License
MIT – use freely.

