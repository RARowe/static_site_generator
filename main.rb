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

def copy_to_dest path
  FileUtils.cp path, path.sub($INPUT_DIR, $OUTPUT_DIR)
end

def process_image path
  copy_to_dest path
  system "sips -s format jpeg -Z 320 #{path} --out #{path.dirname.sub($INPUT_DIR, $OUTPUT_DIR)}/#{path.basename '.*'}_320.jpg"
end

def process_md path
  File.write path.sub($INPUT_DIR, $OUTPUT_DIR).sub_ext('.html'), merge_template('post', Kramdown::Document.new(path.read).to_html)
end

def process_partial_html path
  puts 'processing partial html code goes here'
end

def process_file path
  copy_to_dest path
end

def handle_file path
  case path.extname
  when /jpg|jpeg|png/
    process_image path
  when /md/
    process_md path
  when /partial\.html/
    process_partial_html path
  else
    process_file path
  end
end

$TEMPLATE_DIR = 'templates'# ARGV[0]
$INPUT_DIR = 'test'# ARGV[1]
$OUTPUT_DIR = 'www'# ARGV[2]

directory_paths = []
files = {} 
$TEMPLATES = {}

Find.find($TEMPLATE_DIR) do |f|
  f = Pathname.new f
  if f.file? and f.extname == '.html'
    $TEMPLATES[(f.basename.sub_ext '').to_s] = f.read
  end
end
puts $TEMPLATES

Find.find($INPUT_DIR) do |f|
  output_path = f.sub($INPUT_DIR, $OUTPUT_DIR)
  if File.directory? f
    FileUtils.mkdir_p output_path
  else
    base_path = Pathname.new(output_path).dirname.to_s
    if !files[base_path]
      files[base_path] = []
    end
    files[base_path].push(Pathname.new(f))
  end
end

files.each do |k, v|
  v.each do |f|
    handle_file f
  end
end
