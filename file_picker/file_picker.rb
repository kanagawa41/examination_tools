require 'fileutils'

class InvalidParameter < StandardError; end
PairInfo = Struct.new(:jpg_path, :raw_path)

DEFAULT_OUTPUT_FOLDER_NAME = 'dest'

def usage
<<"EOS"
usage: file_picker [JPEG格納フォルダ] [RAW格納フォルダ] [出力先フォルダ]

JPEG、RAWから同一の名前を持つファイルを抽出し、出力先フォルダにコピーします。
出力先フォルダの指定がない場合は、同階層にフォルダ('#{DEFAULT_OUTPUT_FOLDER_NAME}')を作成し出力します。
出力先フォルダにファイルが存在する場合は、'フォルダ名_日時'の形式でフォルダをリネームします。
EOS
end

def puts_step
puts <<"EOS"
~~~~~~~~~~~~~~~~~~~
EOS
end

def valid_folder?(folder_path)
  raise InvalidParameter.new("#{folder_path} はディレクトリではありません。") unless Dir.exist?(folder_path)
end

def extract_file_basename(file_path)
  File.basename(file_path, File.extname(file_path))
end

def main
  if ARGV.size.zero?
    puts usage
    return
  end
  raise InvalidParameter.new('引数が少なすぎます。') if ARGV.size < 2
  raise InvalidParameter.new('引数が多すぎます。') if ARGV.size > 3

  jpg_folder_path = ARGV[0]
  valid_folder?(jpg_folder_path)
  raw_folder_path = ARGV[1]
  valid_folder?(raw_folder_path)
  dest_folder_path = ARGV[2] || DEFAULT_OUTPUT_FOLDER_NAME

  if !Dir.exist?(dest_folder_path)
    FileUtils.mkdir_p(dest_folder_path)
  elsif Dir.glob("#{dest_folder_path}/*.*").size > 0
    # 既存のフォルダをリネーム
    backup_name = "#{dest_folder_path}_#{Time.now.strftime('%Y%m%d%H%M%S')}"
    File::rename(dest_folder_path, backup_name)
    puts "出力先フォルダにファイルが存在するため #{dest_folder_path} -> #{backup_name} に変更しました。"
    puts_step
    FileUtils.mkdir_p(dest_folder_path)
  end

  puts "JPEG格納フォルダ：#{jpg_folder_path}"
  puts "RAW格納フォルダ：#{raw_folder_path}"
  puts "出力先フォルダ：#{dest_folder_path}"

  puts_step

  jpg_files = Dir.glob("#{jpg_folder_path}/*.*").to_a
  puts "JPEG格納ファイル数：#{jpg_files.size}"
  raw_files = Dir.glob("#{raw_folder_path}/*.*").to_a
  puts "RAW格納ファイル数：#{raw_files.size}"

  pair_infos = []
  jpg_files.each do |jpg_file|
    jpg_basename = extract_file_basename(jpg_file)

    raw_files.each do |raw_file|
      if jpg_basename == extract_file_basename(raw_file)
        pair_infos << PairInfo.new(jpg_file, raw_file)
        break
      end
    end
  end

  puts "名前が一致したファイル数：#{pair_infos.size}"

  pair_infos.each do |pair_info|
    FileUtils.cp(pair_info.jpg_path, dest_folder_path)
    FileUtils.cp(pair_info.raw_path, dest_folder_path)
  end

  puts_step

  puts '作業が完了しました。'
  return true
rescue InvalidParameter => ex
  puts ex.message
  return false
rescue => ex
puts <<"EOS"
#{ex.message}
#{ex.backtrace.join("\n")}
EOS
  return false
end

exit if main ? 0 : 1