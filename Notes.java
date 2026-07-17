// Notes.java
import java.io.*;
import java.nio.file.*;
import java.util.*;
import com.google.gson.*;

class Note {
    String title;
    String content;
    List<Note> children;

    public Note(String title, String content) {
        this.title = title;
        this.content = content;
        this.children = new ArrayList<>();
    }

    public Note find(String title) {
        if (this.title.equals(title)) return this;
        for (Note child : children) {
            Note found = child.find(title);
            if (found != null) return found;
        }
        return null;
    }

    public Note findParent(String title, Note parent) {
        if (this.title.equals(title)) return parent;
        for (Note child : children) {
            Note found = child.findParent(title, this);
            if (found != null) return found;
        }
        return null;
    }

    public boolean delete(String title) {
        for (int i = 0; i < children.size(); i++) {
            if (children.get(i).title.equals(title)) {
                children.remove(i);
                return true;
            }
            if (children.get(i).delete(title)) return true;
        }
        return false;
    }

    public boolean move(String title, Note newParent) {
        Note note = find(title);
        if (note == null) return false;
        Note parent = findParent(title, null);
        if (parent == null) return false;
        parent.children.remove(note);
        newParent.children.add(note);
        return true;
    }

    public void display(int indent) {
        String prefix = children.isEmpty() ? "📄" : "📁";
        System.out.println("  ".repeat(indent) + prefix + " " + title);
        for (Note child : children) child.display(indent + 1);
    }

    public List<Note> search(String term) {
        List<Note> results = new ArrayList<>();
        if (title.toLowerCase().contains(term) || content.toLowerCase().contains(term))
            results.add(this);
        for (Note child : children)
            results.addAll(child.search(term));
        return results;
    }
}

public class Notes {
    private Note root;
    private final String filename = "notes.json";
    private Scanner scanner = new Scanner(System.in);
    private Gson gson = new GsonBuilder().setPrettyPrinting().create();

    public Notes() {
        load();
    }

    public void load() {
        try {
            String json = new String(Files.readAllBytes(Paths.get(filename)));
            root = gson.fromJson(json, Note.class);
        } catch (Exception e) {
            root = new Note("Root", "");
        }
    }

    public void save(String filename) {
        if (filename == null) filename = this.filename;
        try {
            String json = gson.toJson(root);
            Files.write(Paths.get(filename), json.getBytes());
            System.out.println("Saved to " + filename);
        } catch (Exception e) {
            System.out.println("Save failed.");
        }
    }

    public void run() {
        System.out.println("🌳 Tree Notes");
        System.out.println("Commands: add, delete, move, rename, list, view, search, edit, export, import, save, quit");
        while (true) {
            System.out.print("> ");
            String line = scanner.nextLine().trim();
            String[] parts = line.split(" ");
            if (parts.length == 0) continue;
            String cmd = parts[0].toLowerCase();
            switch (cmd) {
                case "quit":
                    save(null);
                    System.out.println("Goodbye!");
                    return;
                case "save":
                    save(null);
                    break;
                case "add":
                    if (parts.length < 3) { System.out.println("Usage: add <parent> <title>"); break; }
                    String parentTitle = String.join(" ", Arrays.copyOfRange(parts, 1, parts.length - 1));
                    String title = parts[parts.length - 1];
                    Note parent = parentTitle.equals("root") ? root : root.find(parentTitle);
                    if (parent == null) { System.out.println("Parent '" + parentTitle + "' not found."); break; }
                    parent.children.add(new Note(title, ""));
                    System.out.println("Added note '" + title + "' under '" + parentTitle + "'");
                    break;
                case "delete":
                    if (parts.length != 2) { System.out.println("Usage: delete <title>"); break; }
                    if (root.delete(parts[1])) System.out.println("Deleted '" + parts[1] + "'");
                    else System.out.println("Note '" + parts[1] + "' not found.");
                    break;
                case "move":
                    if (parts.length < 3) { System.out.println("Usage: move <title> <new_parent>"); break; }
                    String moveTitle = parts[1];
                    String newParentTitle = String.join(" ", Arrays.copyOfRange(parts, 2, parts.length));
                    Note moveNote = root.find(moveTitle);
                    Note newParent = newParentTitle.equals("root") ? root : root.find(newParentTitle);
                    if (moveNote == null) System.out.println("Note '" + moveTitle + "' not found.");
                    else if (newParent == null) System.out.println("Parent '" + newParentTitle + "' not found.");
                    else if (root.move(moveTitle, newParent))
                        System.out.println("Moved '" + moveTitle + "' to '" + newParentTitle + "'");
                    break;
                case "rename":
                    if (parts.length != 3) { System.out.println("Usage: rename <old> <new>"); break; }
                    Note renameNote = root.find(parts[1]);
                    if (renameNote != null) { renameNote.title = parts[2]; System.out.println("Renamed '" + parts[1] + "' to '" + parts[2] + "'"); }
                    else System.out.println("Note '" + parts[1] + "' not found.");
                    break;
                case "list":
                    if (parts.length == 1) root.display(0);
                    else {
                        Note listNote = root.find(String.join(" ", Arrays.copyOfRange(parts, 1, parts.length)));
                        if (listNote != null) listNote.display(0);
                        else System.out.println("Note not found.");
                    }
                    break;
                case "view":
                    if (parts.length != 2) { System.out.println("Usage: view <title>"); break; }
                    Note viewNote = root.find(parts[1]);
                    if (viewNote != null) System.out.println("Title: " + viewNote.title + "\nContent: " + viewNote.content);
                    else System.out.println("Note not found.");
                    break;
                case "edit":
                    if (parts.length < 3) { System.out.println("Usage: edit <title> <content>"); break; }
                    Note editNote = root.find(parts[1]);
                    if (editNote != null) {
                        editNote.content = String.join(" ", Arrays.copyOfRange(parts, 2, parts.length));
                        System.out.println("Updated content for '" + parts[1] + "'");
                    } else System.out.println("Note not found.");
                    break;
                case "search":
                    if (parts.length != 2) { System.out.println("Usage: search <term>"); break; }
                    List<Note> results = root.search(parts[1].toLowerCase());
                    if (!results.isEmpty()) {
                        System.out.println("Found " + results.size() + " notes:");
                        for (Note r : results) {
                            Note p = root.findParent(r.title, null);
                            System.out.println("  " + r.title + " (parent: " + (p != null ? p.title : "root") + ")");
                        }
                    } else System.out.println("No results found.");
                    break;
                case "export":
                    if (parts.length != 2) { System.out.println("Usage: export <file>"); break; }
                    save(parts[1]);
                    break;
                case "import":
                    if (parts.length != 2) { System.out.println("Usage: import <file>"); break; }
                    try {
                        String json = new String(Files.readAllBytes(Paths.get(parts[1])));
                        root = gson.fromJson(json, Note.class);
                        System.out.println("Imported from " + parts[1]);
                    } catch (Exception e) { System.out.println("Failed to import."); }
                    break;
                default:
                    System.out.println("Unknown command.");
            }
        }
    }

    public static void main(String[] args) {
        new Notes().run();
    }
}
