require 'kramdown'
require 'find'
require 'fileutils'
require 'pathname'

class Kramdown::Converter::Html
  def convert_img el, _indent
    src = el.attr["src"]
    link_attributes = { "href" => src }
    el.attr["src"] = src.sub ".png", "_320.jpg"
    el.attr["title"] = el.attr["alt"]
    "<a #{html_attributes(link_attributes)}><img#{html_attributes(el.attr)} /></a>"
  end
end

def merge_template type, content
  $TEMPLATES[type].sub '<##BODY##>', content
end

def write_as_html_file path, contents
  File.write path.sub($INPUT_DIR, $OUTPUT_DIR).sub_ext('.html'), contents
end

def copy_to_dest path
  FileUtils.cp path, path.sub($INPUT_DIR, $OUTPUT_DIR)
end

class SGDir
  def initialize path
    @output_path = path.sub $INPUT_DIR, $OUTPUT_DIR
    @files = []
  end

  def add_file f
    @files.push f
  end

  def write
    FileUtils.mkdir_p @output_path
    write_files
  end

  protected
  def write_files
    @files.each do |f|
      f.write
    end
  end
end

class IndexDir < SGDir
end

class SGFile
  attr_accessor :path
  def initialize path
    @path = Pathname.new path
  end
end

class ImageFile < SGFile
  def write
    copy_to_dest path
    system "sips -s format jpeg -Z 320 #{path} --out #{path.dirname.sub($INPUT_DIR, $OUTPUT_DIR)}/#{path.basename '.*'}_320.jpg"
  end

  def title
    ''
  end
end

class MarkdownFile < SGFile
  def write
    write_as_html_file path, merge_template('post', Kramdown::Document.new(path.read).to_html)
  end

  def title
    path
      .readlines
      .map(&:chomp)
      .find { |l| l.match /#\s/ }
      .sub '# ', ''
  end
end

class HtmlFile < SGFile
  def write
    copy_to_dest path
  end

  def title
    path
      .readlines
      .map(&:chomp)
      .find { |l| l.match /h1/ }
      .sub('<h1>', '')
      .sub('</h1>', '')
  end
end

class PartialHtmlFile < HtmlFile
  def write
    write_as_html_file path, merge_template('post', path.read)
  end
end

def build_file path
  case File.extname path
  when /jpg|jpeg|png/
    ImageFile.new path
  when /md/
    MarkdownFile.new path
  when /phtml/
    PartialHtmlFile.new path
  else
    HtmlFile.new path
  end
end

$TEMPLATE_DIR = 'templates'# ARGV[0]
$INPUT_DIR = 'test'# ARGV[1]
$OUTPUT_DIR = 'www'# ARGV[2]

$TEMPLATES = {}

Find.find($TEMPLATE_DIR) do |f|
  f = Pathname.new f
  if f.file? and f.extname == '.html'
    $TEMPLATES[(f.basename.sub_ext '').to_s] = f.read
  end
end

directories = {}
files = []
Find.find($INPUT_DIR) do |f|
  if File.directory? f
    directories[f] = SGDir.new f
  else
    files.push f
  end
end
puts directories

files.each { |f| directories[File.dirname(f)].add_file(build_file f) }

directories.each do |k, v|
  v.write
end
