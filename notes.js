// notes.js
const fs = require('fs');
const readline = require('readline');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

class Note {
    constructor(title, content = "") {
        this.title = title;
        this.content = content;
        this.children = [];
    }

    toJSON() {
        return {
            title: this.title,
            content: this.content,
            children: this.children.map(c => c.toJSON())
        };
    }

    static fromJSON(data) {
        const note = new Note(data.title, data.content || "");
        note.children = (data.children || []).map(c => Note.fromJSON(c));
        return note;
    }

    find(title) {
        if (this.title === title) return this;
        for (const child of this.children) {
            const found = child.find(title);
            if (found) return found;
        }
        return null;
    }

    findParent(title, parent = null) {
        if (this.title === title) return parent;
        for (const child of this.children) {
            const found = child.findParent(title, this);
            if (found !== null) return found;
        }
        return null;
    }

    delete(title) {
        for (let i = 0; i < this.children.length; i++) {
            if (this.children[i].title === title) {
                this.children.splice(i, 1);
                return true;
            }
            if (this.children[i].delete(title)) return true;
        }
        return false;
    }

    move(title, newParent) {
        const note = this.find(title);
        if (!note) return false;
        const parent = this.findParent(title);
        if (!parent) return false;
        const idx = parent.children.indexOf(note);
        if (idx > -1) parent.children.splice(idx, 1);
        newParent.children.push(note);
        return true;
    }

    display(indent = 0) {
        const prefix = this.children.length ? "📁" : "📄";
        console.log("  ".repeat(indent) + prefix + " " + this.title);
        this.children.forEach(c => c.display(indent + 1));
    }

    search(term) {
        let results = [];
        if (this.title.toLowerCase().includes(term) || this.content.toLowerCase().includes(term)) {
            results.push(this);
        }
        this.children.forEach(c => {
            results = results.concat(c.search(term));
        });
        return results;
    }
}

class App {
    constructor() {
        this.filename = "notes.json";
        this.root = new Note("Root");
        this.load();
    }

    load() {
        try {
            if (fs.existsSync(this.filename)) {
                const data = JSON.parse(fs.readFileSync(this.filename, 'utf8'));
                this.root = Note.fromJSON(data);
            }
        } catch (e) {
            this.root = new Note("Root");
        }
    }

    save(filename = this.filename) {
        fs.writeFileSync(filename, JSON.stringify(this.root.toJSON(), null, 2));
        console.log(`Saved to ${filename}`);
    }

    ask(question) {
        return new Promise(resolve => rl.question(question, resolve));
    }

    async run() {
        console.log("🌳 Tree Notes");
        console.log("Commands: add, delete, move, rename, list, view, search, edit, export, import, save, quit");
        while (true) {
            const input = await this.ask("> ");
            const parts = input.trim().split(/\s+/);
            if (!parts.length) continue;
            const cmd = parts[0].toLowerCase();
            switch (cmd) {
                case "quit":
                    this.save();
                    console.log("Goodbye!");
                    rl.close();
                    return;
                case "save":
                    this.save();
                    break;
                case "add":
                    if (parts.length < 3) {
                        console.log("Usage: add <parent> <title>");
                        break;
                    }
                    const parentTitle = parts.slice(1, -1).join(" ");
                    const title = parts[parts.length - 1];
                    const parent = parentTitle === "root" ? this.root : this.root.find(parentTitle);
                    if (!parent) { console.log(`Parent '${parentTitle}' not found.`); break; }
                    parent.children.push(new Note(title));
                    console.log(`Added note '${title}' under '${parentTitle}'`);
                    break;
                case "delete":
                    if (parts.length !== 2) { console.log("Usage: delete <title>"); break; }
                    const delTitle = parts[1];
                    if (this.root.delete(delTitle)) console.log(`Deleted '${delTitle}'`);
                    else console.log(`Note '${delTitle}' not found.`);
                    break;
                case "move":
                    if (parts.length < 3) { console.log("Usage: move <title> <new_parent>"); break; }
                    const moveTitle = parts[1];
                    const newParentTitle = parts.slice(2).join(" ");
                    const note = this.root.find(moveTitle);
                    const newParent = newParentTitle === "root" ? this.root : this.root.find(newParentTitle);
                    if (!note) console.log(`Note '${moveTitle}' not found.`);
                    else if (!newParent) console.log(`Parent '${newParentTitle}' not found.`);
                    else if (this.root.move(moveTitle, newParent)) {
                        console.log(`Moved '${moveTitle}' to '${newParentTitle}'`);
                    }
                    break;
                case "rename":
                    if (parts.length !== 3) { console.log("Usage: rename <old> <new>"); break; }
                    const oldTitle = parts[1], newTitle = parts[2];
                    const renameNote = this.root.find(oldTitle);
                    if (renameNote) { renameNote.title = newTitle; console.log(`Renamed '${oldTitle}' to '${newTitle}'`); }
                    else console.log(`Note '${oldTitle}' not found.`);
                    break;
                case "list":
                    if (parts.length === 1) this.root.display();
                    else {
                        const listTitle = parts.slice(1).join(" ");
                        const listNote = this.root.find(listTitle);
                        if (listNote) listNote.display();
                        else console.log("Note not found.");
                    }
                    break;
                case "view":
                    if (parts.length !== 2) { console.log("Usage: view <title>"); break; }
                    const viewNote = this.root.find(parts[1]);
                    if (viewNote) console.log(`Title: ${viewNote.title}\nContent: ${viewNote.content}`);
                    else console.log("Note not found.");
                    break;
                case "edit":
                    if (parts.length < 3) { console.log("Usage: edit <title> <content>"); break; }
                    const editTitle = parts[1];
                    const content = parts.slice(2).join(" ");
                    const editNote = this.root.find(editTitle);
                    if (editNote) { editNote.content = content; console.log(`Updated content for '${editTitle}'`); }
                    else console.log("Note not found.");
                    break;
                case "search":
                    if (parts.length !== 2) { console.log("Usage: search <term>"); break; }
                    const results = this.root.search(parts[1].toLowerCase());
                    if (results.length) {
                        console.log(`Found ${results.length} notes:`);
                        results.forEach(r => {
                            const parent = this.root.findParent(r.title);
                            const pTitle = parent ? parent.title : "root";
                            console.log(`  ${r.title} (parent: ${pTitle})`);
                        });
                    } else console.log("No results found.");
                    break;
                case "export":
                    if (parts.length !== 2) { console.log("Usage: export <file>"); break; }
                    this.save(parts[1]);
                    break;
                case "import":
                    if (parts.length !== 2) { console.log("Usage: import <file>"); break; }
                    try {
                        const data = JSON.parse(fs.readFileSync(parts[1], 'utf8'));
                        this.root = Note.fromJSON(data);
                        console.log(`Imported from ${parts[1]}`);
                    } catch (e) { console.log("Failed to import."); }
                    break;
                default:
                    console.log("Unknown command.");
            }
        }
    }
}

const app = new App();
app.run().catch(console.error);
