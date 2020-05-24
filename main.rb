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

def merge_post_template title, body
  ERB.new(File.read('templates/post.html.erb')).result_with_hash({ title: title, body: body })
end

def merge_index_template title, body, posts
  ERB.new(File.read('templates/post.html.erb')).result_with_hash({ title: title, body: body, posts: posts })
end

def write_as_html_file path, contents
  File.write path.sub($INPUT_DIR, $OUTPUT_DIR).sub_ext('.html'), contents
end

def copy_to_dest path
  FileUtils.cp path, path.sub($INPUT_DIR, $OUTPUT_DIR)
end

class NullObject
  def method_missing(*args, &block)
    nil
  end
end

def build_image_dir path
  if File.exist? path
    ImageDir.new path
  else
    NullObject.new
  end
end

def build_index_file dir
  if File.exist? "#{dir.path}/index.md"
    IndexMarkdownFile.new dir
  elsif File.exist? "#{dir.path}/index.phtml"
    IndexPartialHtmlFile.new dir
  elsif File.exist? "#{dir.path}/index.html"
    HtmlFile.new "#{dir.path}/index.html"
  else
    IndexFile.new dir, ''
  end
end

def build_file path
  case File.extname path
  when /md/
    MarkdownFile.new path
  when /phtml/
    PartialHtmlFile.new path
  when /link/
    LinkFile.new path
  else
    HtmlFile.new path
  end
end

def build_entry path
  if File.directory? path
    SGDir.new path
  else
    if File.basename(path).include? 'index'
      build_index_file path
    else
      build_file path
    end
  end
end

class IndexFile
  def initialize dir, file_type
    @dir = dir
    @path = "#{dir.path}/index.#{file_type}"
    @output_path = "#{dir.output_path}/index.html"
  end

  def write
    File.write @output_path, merge_index_template(@dir.title, body, @dir.posts)
  end

  def body
    ''
  end
end

class IndexMarkdownFile < IndexFile
  def initialize dir
    super dir, 'md'
  end

  def body
    Kramdown::Document.new(File.read path).to_html
  end
end

class IndexPartialHtmlFile < IndexFile
  def initialize dir
    super dir, 'phtml'
  end

  def body
    File.read @path
  end
end

class SGDir
  attr_accessor :path, :output_path, :posts, :title, :id, :link
  def initialize path
    @path = path
    @output_path = path.sub $INPUT_DIR, $OUTPUT_DIR
    @image_dir = build_image_dir path
    @index_file = build_index_file self
    @posts = get_posts path
    @title = File.basename(path).gsub('_', ' ').split.map(&:capitalize).join ' '
    @id = @title.gsub(' ', '-')
    @link = File.basename path
  end

  def write
    FileUtils.mkdir_p @output_path
    @image_dir.write
    @index_file.write
    @posts.each do |e|
      e.write
    end
  end

  private
  def get_posts path
    Dir
      .entries(path)
      .filter { |e| !e.start_with?('.') and !e.include?('index.') }
      .map { |e| build_entry "#{path}/#{e}" }
  end
end

class ImageDir
  def initialize path
    @directories = []
    @files = []
    Find.find(path) do |f|
      if File.directory? f
        @directories.push f.sub($INPUT_DIR, $OUTPUT_DIR)
      else
        @files.push f
      end
    end
  end

  def write
    @directories.each do |d|
      FileUtils.mkdir_p d
    end

    @files.each do |f|
      out_path = File.dirname f.sub($INPUT_DIR, $OUTPUT_DIR)
      file_name = File.basename f, '.*'
      copy_to_dest f
      system "sips -s format jpeg -Z 320 #{f} --out #{out_path}/#{file_name}_320.jpg"
    end
  end
end

class SGFile
  attr_accessor :path, :out_path, :link
  def initialize path
    @path = Pathname.new path
    @out_path = @path.dirname.sub($INPUT_DIR, $OUTPUT_DIR)
    @link = File.basename path
  end

  def basename
    @out_path.basename
  end

  def id
    title.gsub(' ', '-')
  end

  def title
    ''
  end
end

class MarkdownFile < SGFile
  def write
    write_as_html_file path, merge_post_template(title, Kramdown::Document.new(path.read).to_html)
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
    File.readlines(path.to_s)
      .map(&:chomp)
      .find { |l| l.match /h1/ }
      .sub('<h1>', '')
      .sub('</h1>', '')
  end
end

class PartialHtmlFile < HtmlFile
  def write
    write_as_html_file path, merge_post_template(title, path.read)
  end
end

class LinkFile
  def initialize path
    @config = Hash[
      File.readlines(path)
        .map(&:chomp)
        .map { |l| l.split(',') }
    ]
  end

  def write
  end

  def id
    title.gsub(' ', '-')
  end

  def title
    "#{@config['title']} [external link]"
  end

  def link
    @config['link']
  end
end

$INPUT_DIR = 'test'# ARGV[1]
$OUTPUT_DIR = 'www'# ARGV[2]

SGDir.new('test').write
#directories = {}
#files = []
#Find.find($INPUT_DIR) do |f|
#  if File.directory? f
#    directories[f] = SGDir.new f
#  end
#  files.push f
#end
#
#files.each { |f| directories[File.dirname(f)].add_file(build_entry f) }
#
#directories.each do |k, v|
#  v.write
#end
