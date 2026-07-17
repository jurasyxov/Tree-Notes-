// notes.go
package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

type Note struct {
	Title    string  `json:"title"`
	Content  string  `json:"content"`
	Children []*Note `json:"children"`
}

func NewNote(title string) *Note {
	return &Note{Title: title, Content: "", Children: []*Note{}}
}

func (n *Note) Find(title string) *Note {
	if n.Title == title {
		return n
	}
	for _, child := range n.Children {
		if found := child.Find(title); found != nil {
			return found
		}
	}
	return nil
}

func (n *Note) FindParent(title string, parent *Note) *Note {
	if n.Title == title {
		return parent
	}
	for _, child := range n.Children {
		if found := child.FindParent(title, n); found != nil {
			return found
		}
	}
	return nil
}

func (n *Note) Delete(title string) bool {
	for i, child := range n.Children {
		if child.Title == title {
			n.Children = append(n.Children[:i], n.Children[i+1:]...)
			return true
		}
		if child.Delete(title) {
			return true
		}
	}
	return false
}

func (n *Note) Move(title string, newParent *Note) bool {
	note := n.Find(title)
	if note == nil {
		return false
	}
	parent := n.FindParent(title, nil)
	if parent == nil {
		return false
	}
	// Remove from parent
	for i, child := range parent.Children {
		if child == note {
			parent.Children = append(parent.Children[:i], parent.Children[i+1:]...)
			break
		}
	}
	newParent.Children = append(newParent.Children, note)
	return true
}

func (n *Note) Display(indent int) {
	prefix := "📁"
	if len(n.Children) == 0 {
		prefix = "📄"
	}
	fmt.Println(strings.Repeat("  ", indent) + prefix + " " + n.Title)
	for _, child := range n.Children {
		child.Display(indent + 1)
	}
}

func (n *Note) Search(term string) []*Note {
	var results []*Note
	if strings.Contains(strings.ToLower(n.Title), strings.ToLower(term)) ||
		strings.Contains(strings.ToLower(n.Content), strings.ToLower(term)) {
		results = append(results, n)
	}
	for _, child := range n.Children {
		results = append(results, child.Search(term)...)
	}
	return results
}

type App struct {
	root     *Note
	filename string
}

func NewApp() *App {
	return &App{filename: "notes.json"}
}

func (a *App) Load() {
	if data, err := os.ReadFile(a.filename); err == nil {
		var root Note
		if err := json.Unmarshal(data, &root); err == nil {
			a.root = &root
			return
		}
	}
	a.root = NewNote("Root")
}

func (a *App) Save(filename ...string) {
	fname := a.filename
	if len(filename) > 0 && filename[0] != "" {
		fname = filename[0]
	}
	data, _ := json.MarshalIndent(a.root, "", "  ")
	os.WriteFile(fname, data, 0644)
	fmt.Printf("Saved to %s\n", fname)
}

func (a *App) Run() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("🌳 Tree Notes")
	fmt.Println("Commands: add, delete, move, rename, list, view, search, edit, export, import, save, quit")
	for {
		fmt.Print("> ")
		if !scanner.Scan() {
			break
		}
		parts := strings.Fields(scanner.Text())
		if len(parts) == 0 {
			continue
		}
		cmd := strings.ToLower(parts[0])
		switch cmd {
		case "quit":
			a.Save()
			fmt.Println("Goodbye!")
			return
		case "save":
			a.Save()
		case "add":
			if len(parts) < 3 {
				fmt.Println("Usage: add <parent> <title>")
				continue
			}
			parentTitle := strings.Join(parts[1:len(parts)-1], " ")
			title := parts[len(parts)-1]
			parent := a.root.Find(parentTitle)
			if parentTitle == "root" {
				parent = a.root
			}
			if parent == nil {
				fmt.Printf("Parent '%s' not found.\n", parentTitle)
				continue
			}
			parent.Children = append(parent.Children, NewNote(title))
			fmt.Printf("Added note '%s' under '%s'\n", title, parentTitle)
		case "delete":
			if len(parts) != 2 {
				fmt.Println("Usage: delete <title>")
				continue
			}
			title := parts[1]
			if a.root.Delete(title) {
				fmt.Printf("Deleted '%s'\n", title)
			} else {
				fmt.Printf("Note '%s' not found.\n", title)
			}
		case "move":
			if len(parts) < 3 {
				fmt.Println("Usage: move <title> <new_parent>")
				continue
			}
			title := parts[1]
			newParentTitle := strings.Join(parts[2:], " ")
			note := a.root.Find(title)
			newParent := a.root.Find(newParentTitle)
			if newParentTitle == "root" {
				newParent = a.root
			}
			if note == nil {
				fmt.Printf("Note '%s' not found.\n", title)
			} else if newParent == nil {
				fmt.Printf("Parent '%s' not found.\n", newParentTitle)
			} else {
				if a.root.Move(title, newParent) {
					fmt.Printf("Moved '%s' to '%s'\n", title, newParentTitle)
				}
			}
		case "rename":
			if len(parts) != 3 {
				fmt.Println("Usage: rename <old> <new>")
				continue
			}
			old, new := parts[1], parts[2]
			note := a.root.Find(old)
			if note != nil {
				note.Title = new
				fmt.Printf("Renamed '%s' to '%s'\n", old, new)
			} else {
				fmt.Printf("Note '%s' not found.\n", old)
			}
		case "list":
			if len(parts) == 1 {
				a.root.Display(0)
			} else {
				title := strings.Join(parts[1:], " ")
				note := a.root.Find(title)
				if note != nil {
					note.Display(0)
				} else {
					fmt.Println("Note not found.")
				}
			}
		case "view":
			if len(parts) != 2 {
				fmt.Println("Usage: view <title>")
				continue
			}
			note := a.root.Find(parts[1])
			if note != nil {
				fmt.Printf("Title: %s\nContent: %s\n", note.Title, note.Content)
			} else {
				fmt.Println("Note not found.")
			}
		case "edit":
			if len(parts) < 3 {
				fmt.Println("Usage: edit <title> <content>")
				continue
			}
			title := parts[1]
			content := strings.Join(parts[2:], " ")
			note := a.root.Find(title)
			if note != nil {
				note.Content = content
				fmt.Printf("Updated content for '%s'\n", title)
			} else {
				fmt.Println("Note not found.")
			}
		case "search":
			if len(parts) != 2 {
				fmt.Println("Usage: search <term>")
				continue
			}
			results := a.root.Search(parts[1])
			if len(results) > 0 {
				fmt.Printf("Found %d notes:\n", len(results))
				for _, r := range results {
					parent := a.root.FindParent(r.Title, nil)
					parentTitle := "root"
					if parent != nil {
						parentTitle = parent.Title
					}
					fmt.Printf("  %s (parent: %s)\n", r.Title, parentTitle)
				}
			} else {
				fmt.Println("No results found.")
			}
		case "export":
			if len(parts) != 2 {
				fmt.Println("Usage: export <file>")
				continue
			}
			a.Save(parts[1])
		case "import":
			if len(parts) != 2 {
				fmt.Println("Usage: import <file>")
				continue
			}
			data, err := os.ReadFile(parts[1])
			if err != nil {
				fmt.Println("Failed to import.")
				continue
			}
			var root Note
			if err := json.Unmarshal(data, &root); err == nil {
				a.root = &root
				fmt.Printf("Imported from %s\n", parts[1])
			} else {
				fmt.Println("Failed to import.")
			}
		default:
			fmt.Println("Unknown command.")
		}
	}
}

func main() {
	app := NewApp()
	app.Load()
	app.Run()
}
