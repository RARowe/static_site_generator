module SGHelpers
  def build_path(parent, path)
    if parent
      "#{parent.path}/#{path}"
    else
      "#{path}"
    end
  end
end

module SGHTMLHelpers
  def toHTML line
    case line
    when title
      to_h1_tag line.sub(title, '')
    when paragraph
      to_p_tag line
    else
      puts "DID NOT KNOW WHAT TO DO"
      "<blink></blink>"
    end
  end

  def title
    /^#\s/
  end

  def paragraph
    /^[a-zA-Z\d]/
  end

  def to_h1_tag text
    "<h1 id=\"#{text.downcase.gsub(' ', '-')}\">#{text}</h1>"
  end

  def to_p_tag text
    "<p>#{text}</p>"
  end
end

class SGFile
  include SGHelpers
  def initialize(parent, path)
    @parent = parent
    @path = path
    process
  end

  def path
    build_path @parent, @path
  end

  def process
    puts "plain old files don't get processed"
  end
end

class SGMarkdownFile < SGFile
  include SGHTMLHelpers
  def process
    puts File
      .readlines(path)
      .map(&:chomp)
      .filter { |f| !f.empty? }
      .map { |f| toHTML f }
      .join("\n")
  end
end

class SGHTMLFile < SGFile
  def process
    puts 'processing html file'
  end
end

class SGImageFile < SGFile
  def process
    puts 'processing image file'
  end
end

class SGDir
  include SGHelpers
  def initialize(path, parent = nil)
    @path = path
    @parent = parent
    @directories = []
    @files = []
  end

  def process
    Dir.foreach(path) do |path|
      if File.directory? path
        @directories.push SGDir.new(path) unless bad_dir? path
      else
        @files.push build_file(path) unless bad_file? path
      end
    end

    @directories.each do |d|
      d.process
    end
  end

  def path
    build_path @parent, @path
  end

  private
  def bad_dir? d
    d == '.' or d == '..'
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

d = SGDir.new '.'
d.process
