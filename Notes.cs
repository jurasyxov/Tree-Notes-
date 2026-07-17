// Notes.cs
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;

class Note
{
    public string Title { get; set; }
    public string Content { get; set; }
    public List<Note> Children { get; set; }

    public Note(string title, string content = "")
    {
        Title = title;
        Content = content;
        Children = new List<Note>();
    }

    public Note Find(string title)
    {
        if (Title == title) return this;
        foreach (var child in Children)
        {
            var result = child.Find(title);
            if (result != null) return result;
        }
        return null;
    }

    public Note FindParent(string title, Note parent = null)
    {
        if (Title == title) return parent;
        foreach (var child in Children)
        {
            var result = child.FindParent(title, this);
            if (result != null) return result;
        }
        return null;
    }

    public bool Delete(string title)
    {
        for (int i = 0; i < Children.Count; i++)
        {
            if (Children[i].Title == title)
            {
                Children.RemoveAt(i);
                return true;
            }
            if (Children[i].Delete(title)) return true;
        }
        return false;
    }

    public bool Move(string title, Note newParent)
    {
        var note = Find(title);
        if (note == null) return false;
        var parent = FindParent(title);
        if (parent == null) return false;
        parent.Children.Remove(note);
        newParent.Children.Add(note);
        return true;
    }

    public void Display(int indent = 0)
    {
        string prefix = Children.Count > 0 ? "📁" : "📄";
        Console.WriteLine(new string(' ', indent * 2) + prefix + " " + Title);
        foreach (var child in Children) child.Display(indent + 1);
    }

    public List<Note> Search(string term)
    {
        var results = new List<Note>();
        if (Title.ToLower().Contains(term) || Content.ToLower().Contains(term))
            results.Add(this);
        foreach (var child in Children)
            results.AddRange(child.Search(term));
        return results;
    }
}

class App
{
    private Note root;
    private string filename = "notes.json";

    public App()
    {
        Load();
    }

    public void Load()
    {
        if (File.Exists(filename))
        {
            try
            {
                string json = File.ReadAllText(filename);
                root = JsonSerializer.Deserialize<Note>(json);
                return;
            }
            catch { }
        }
        root = new Note("Root");
    }

    public void Save(string filename = null)
    {
        if (filename == null) filename = this.filename;
        string json = JsonSerializer.Serialize(root, new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(filename, json);
        Console.WriteLine($"Saved to {filename}");
    }

    public void Run()
    {
        Console.WriteLine("🌳 Tree Notes");
        Console.WriteLine("Commands: add, delete, move, rename, list, view, search, edit, export, import, save, quit");
        while (true)
        {
            Console.Write("> ");
            string input = Console.ReadLine()?.Trim() ?? "";
            string[] parts = input.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length == 0) continue;
            string cmd = parts[0].ToLower();
            switch (cmd)
            {
                case "quit":
                    Save();
                    Console.WriteLine("Goodbye!");
                    return;
                case "save":
                    Save();
                    break;
                case "add":
                    if (parts.Length < 3) { Console.WriteLine("Usage: add <parent> <title>"); break; }
                    string parentTitle = string.Join(" ", parts, 1, parts.Length - 2);
                    string title = parts[parts.Length - 1];
                    Note parent = parentTitle == "root" ? root : root.Find(parentTitle);
                    if (parent == null) { Console.WriteLine($"Parent '{parentTitle}' not found."); break; }
                    parent.Children.Add(new Note(title));
                    Console.WriteLine($"Added note '{title}' under '{parentTitle}'");
                    break;
                case "delete":
                    if (parts.Length != 2) { Console.WriteLine("Usage: delete <title>"); break; }
                    if (root.Delete(parts[1])) Console.WriteLine($"Deleted '{parts[1]}'");
                    else Console.WriteLine($"Note '{parts[1]}' not found.");
                    break;
                case "move":
                    if (parts.Length < 3) { Console.WriteLine("Usage: move <title> <new_parent>"); break; }
                    string moveTitle = parts[1];
                    string newParentTitle = string.Join(" ", parts, 2, parts.Length - 2);
                    Note moveNote = root.Find(moveTitle);
                    Note newParent = newParentTitle == "root" ? root : root.Find(newParentTitle);
                    if (moveNote == null) Console.WriteLine($"Note '{moveTitle}' not found.");
                    else if (newParent == null) Console.WriteLine($"Parent '{newParentTitle}' not found.");
                    else if (root.Move(moveTitle, newParent))
                        Console.WriteLine($"Moved '{moveTitle}' to '{newParentTitle}'");
                    break;
                case "rename":
                    if (parts.Length != 3) { Console.WriteLine("Usage: rename <old> <new>"); break; }
                    Note renameNote = root.Find(parts[1]);
                    if (renameNote != null) { renameNote.Title = parts[2]; Console.WriteLine($"Renamed '{parts[1]}' to '{parts[2]}'"); }
                    else Console.WriteLine($"Note '{parts[1]}' not found.");
                    break;
                case "list":
                    if (parts.Length == 1) root.Display();
                    else
                    {
                        Note listNote = root.Find(string.Join(" ", parts, 1, parts.Length - 1));
                        if (listNote != null) listNote.Display();
                        else Console.WriteLine("Note not found.");
                    }
                    break;
                case "view":
                    if (parts.Length != 2) { Console.WriteLine("Usage: view <title>"); break; }
                    Note viewNote = root.Find(parts[1]);
                    if (viewNote != null) Console.WriteLine($"Title: {viewNote.Title}\nContent: {viewNote.Content}");
                    else Console.WriteLine("Note not found.");
                    break;
                case "edit":
                    if (parts.Length < 3) { Console.WriteLine("Usage: edit <title> <content>"); break; }
                    Note editNote = root.Find(parts[1]);
                    if (editNote != null) { editNote.Content = string.Join(" ", parts, 2, parts.Length - 2); Console.WriteLine($"Updated content for '{parts[1]}'"); }
                    else Console.WriteLine("Note not found.");
                    break;
                case "search":
                    if (parts.Length != 2) { Console.WriteLine("Usage: search <term>"); break; }
                    var results = root.Search(parts[1].ToLower());
                    if (results.Count > 0)
                    {
                        Console.WriteLine($"Found {results.Count} notes:");
                        foreach (var r in results)
                        {
                            Note p = root.FindParent(r.Title);
                            Console.WriteLine($"  {r.Title} (parent: {(p != null ? p.Title : "root")})");
                        }
                    }
                    else Console.WriteLine("No results found.");
                    break;
                case "export":
                    if (parts.Length != 2) { Console.WriteLine("Usage: export <file>"); break; }
                    Save(parts[1]);
                    break;
                case "import":
                    if (parts.Length != 2) { Console.WriteLine("Usage: import <file>"); break; }
                    try
                    {
                        string json = File.ReadAllText(parts[1]);
                        root = JsonSerializer.Deserialize<Note>(json);
                        Console.WriteLine($"Imported from {parts[1]}");
                    }
                    catch { Console.WriteLine("Failed to import."); }
                    break;
                default:
                    Console.WriteLine("Unknown command.");
                    break;
            }
        }
    }

    static void Main()
    {
        var app = new App();
        app.Run();
    }
}
