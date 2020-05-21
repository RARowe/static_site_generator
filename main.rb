require 'kramdown'
require 'find'
require 'fileutils'
require 'pathname'

def copy_to_dest path
  FileUtils.cp path, path.sub($INPUT_DIR, $OUTPUT_DIR)
end

def process_image path
  copy_to_dest path
  system "sips -s format jpeg -Z 320 #{path} --out #{path.dirname.sub($INPUT_DIR, $OUTPUT_DIR)}/#{path.basename '.*'}_320.jpg"
end

def process_md path
  File.write path.sub($INPUT_DIR, $OUTPUT_DIR).sub_ext('.html'), Kramdown::Document.new(path.read).to_html
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
  else
    process_file path
  end
end

$INPUT_DIR = ARGV[0]
$OUTPUT_DIR = ARGV[1]

directory_paths = []
files = {} 

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
