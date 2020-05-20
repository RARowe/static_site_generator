require 'kramdown'
require 'find'
require 'fileutils'
require 'pathname'

def process_image path
  File.read(path)
end

def process_md path
  Kramdown::Document.new(File.read(path)).to_html
end

def handle_file path
  file_contents = ''
  file_extension = ''
  case File.extname path
  when /jpg|jpeg|png/
    # file_contents = process_image path
    file_extension = '.jpg'
  when /md/
    file_contents = process_md path
    file_extension = '.html'
  else
    file_contents = File.read(path)
    file_extension = File.extname path
  end

  File.write Pathname.new(path).sub($INPUT_DIR, $OUTPUT_DIR).sub_ext(file_extension), file_contents
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
    files[base_path].push(f)
  end
end

files.each do |k, v|
  v.each do |f|
    handle_file f
  end
end
