require 'kramdown'

module SGHelpers
  def build_path(parent, name)
    if parent
      "#{parent.path}/#{name}"
    else
      "./#{name}"
    end
  end
end

class SGFile
  include SGHelpers
  attr_accessor :name
  def initialize(parent, name)
    @parent = parent
    @name = name
  end

  def path
    build_path @parent, @name
  end

  def process
  end
end

class SGMarkdownFile < SGFile
  def process
    Kramdown::Document.new(File.read(path)).to_html
  end
end

class SGHTMLFile < SGFile
  def process
    File.read(path)
  end
end

class SGImageFile < SGFile
  def process
  end
end

class SGDir
  include SGHelpers
  attr_accessor :name
  def initialize(name, parent = nil, output_dir = '')
    @name = name
    @parent = parent
    @directories = []
    @files = []
    @output_dir = output_dir
  end

  def process
    puts "Processing #{path}...\n\n"
    Dir.foreach(path) do |p|
      if File.directory? "#{path}/#{p}"
        @directories.push SGDir.new(p, self) unless bad_dir? p
      else
        @files.push build_file(p) unless bad_file? p
      end
    end

    @directories.each do |d|
      d.process
    end

    @files.each do |f|
      f.process
    end
  end

  def write
  end

  def path
    build_path @parent, @name
  end

  private
  def bad_dir? d
    d == '.' or d == '..' or d.start_with? '.'
  end

  def bad_file? f
    f.include? 'swp' or f.start_with? '.'
  end

  def build_file path
    case File.extname path
    when /jpg|jpeg|png/
      SGImageFile.new self, path
    when /html/
      SGHTMLFile.new self, path
    when /md/
      SGMarkdownFile.new self, path
    else
      SGFile.new self, path
    end
  end
end

d = SGDir.new 'www', 'out'
d.process
