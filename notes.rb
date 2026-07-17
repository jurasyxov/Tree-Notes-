# notes.rb
require 'json'

class Note
  attr_accessor :title, :content, :children

  def initialize(title, content = "")
    @title = title
    @content = content
    @children = []
  end

  def to_h
    {
      title: @title,
      content: @content,
      children: @children.map(&:to_h)
    }
  end

  def self.from_h(data)
    note = new(data["title"], data["content"] || "")
    data["children"].each { |c| note.children << from_h(c) } if data["children"]
    note
  end

  def find(title)
    return self if @title == title
    @children.each do |child|
      result = child.find(title)
      return result if result
    end
    nil
  end

  def find_parent(title, parent = nil)
    return parent if @title == title
    @children.each do |child|
      result = child.find_parent(title, self)
      return result if result
    end
    nil
  end

  def delete(title)
    @children.each_with_index do |child, i|
      if child.title == title
        @children.delete_at(i)
        return true
      end
      return true if child.delete(title)
    end
    false
  end

  def move(title, new_parent)
    note = find(title)
    return false unless note
    parent = find_parent(title)
    return false unless parent
    parent.children.delete(note)
    new_parent.children << note
    true
  end

  def display(indent = 0)
    prefix = @children.empty? ? "📄" : "📁"
    puts "  " * indent + "#{prefix} #{@title}"
    @children.each { |c| c.display(indent + 1) }
  end

  def search(term)
    results = []
    if @title.downcase.include?(term) || @content.downcase.include?(term)
      results << self
    end
    @children.each { |c| results.concat(c.search(term)) }
    results
  end
end

class App
  def initialize
    @filename = "notes.json"
    @root = Note.new("Root")
    load
  end

  def load
    if File.exist?(@filename)
      begin
        data = JSON.parse(File.read(@filename))
        @root = Note.from_h(data)
      rescue
        @root = Note.new("Root")
      end
    end
  end

  def save(filename = nil)
    filename ||= @filename
    File.write(filename, JSON.pretty_generate(@root.to_h))
    puts "Saved to #{filename}"
  end

  def run
    puts "🌳 Tree Notes"
    puts "Commands: add, delete, move, rename, list, view, search, edit, export, import, save, quit"
    loop do
      print "> "
      input = gets.chomp.strip
      parts = input.split
      next if parts.empty?
      cmd = parts[0].downcase
      case cmd
      when "quit"
        save
        puts "Goodbye!"
        break
      when "save"
        save
      when "add"
        if parts.size < 3
          puts "Usage: add <parent> <title>"
          next
        end
        parent_title = parts[1...-1].join(" ")
        title = parts[-1]
        parent = parent_title == "root" ? @root : @root.find(parent_title)
        unless parent
          puts "Parent '#{parent_title}' not found."
          next
        end
        parent.children << Note.new(title)
        puts "Added note '#{title}' under '#{parent_title}'"
      when "delete"
        if parts.size != 2
          puts "Usage: delete <title>"
          next
        end
        if @root.delete(parts[1])
          puts "Deleted '#{parts[1]}'"
        else
          puts "Note '#{parts[1]}' not found."
        end
      when "move"
        if parts.size < 3
          puts "Usage: move <title> <new_parent>"
          next
        end
        move_title = parts[1]
        new_parent_title = parts[2..-1].join(" ")
        note = @root.find(move_title)
        new_parent = new_parent_title == "root" ? @root : @root.find(new_parent_title)
        unless note
          puts "Note '#{move_title}' not found."
        elsif !new_parent
          puts "Parent '#{new_parent_title}' not found."
        elsif @root.move(move_title, new_parent)
          puts "Moved '#{move_title}' to '#{new_parent_title}'"
        end
      when "rename"
        if parts.size != 3
          puts "Usage: rename <old> <new>"
          next
        end
        note = @root.find(parts[1])
        if note
          note.title = parts[2]
          puts "Renamed '#{parts[1]}' to '#{parts[2]}'"
        else
          puts "Note '#{parts[1]}' not found."
        end
      when "list"
        if parts.size == 1
          @root.display
        else
          note = @root.find(parts[1..-1].join(" "))
          if note
            note.display
          else
            puts "Note not found."
          end
        end
      when "view"
        if parts.size != 2
          puts "Usage: view <title>"
          next
        end
        note = @root.find(parts[1])
        if note
          puts "Title: #{note.title}"
          puts "Content: #{note.content}"
        else
          puts "Note not found."
        end
      when "edit"
        if parts.size < 3
          puts "Usage: edit <title> <content>"
          next
        end
        note = @root.find(parts[1])
        if note
          note.content = parts[2..-1].join(" ")
          puts "Updated content for '#{parts[1]}'"
        else
          puts "Note not found."
        end
      when "search"
        if parts.size != 2
          puts "Usage: search <term>"
          next
        end
        results = @root.search(parts[1].downcase)
        if results.any?
          puts "Found #{results.size} notes:"
          results.each do |r|
            parent = @root.find_parent(r.title)
            puts "  #{r.title} (parent: #{parent ? parent.title : 'root'})"
          end
        else
          puts "No results found."
        end
      when "export"
        if parts.size != 2
          puts "Usage: export <file>"
          next
        end
        save(parts[1])
      when "import"
        if parts.size != 2
          puts "Usage: import <file>"
          next
        end
        begin
          data = JSON.parse(File.read(parts[1]))
          @root = Note.from_h(data)
          puts "Imported from #{parts[1]}"
        rescue
          puts "Failed to import."
        end
      else
        puts "Unknown command."
      end
    end
  end
end

App.new.run if __FILE__ == $0
