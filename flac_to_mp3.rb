# Copyright (c) 2009 John Wulff <johnwulff@gmail.com> http://www.johnwulff.com
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'find'
require 'yaml'

source      = File.expand_path ARGV[0]
destination = File.expand_path ARGV[1]

# Collect paths for all of the FLAC files in the source path.
flac_paths = []
Find.find(source) do |path|
  flac_paths << path if File.extname(path).downcase == '.flac'
end
puts "Found #{flac_paths.size} FLAC files in #{source}"

# Collect paths for all of the MP3 files in the destination path.
mp3_paths = []
Find.find(destination) do |path|
  mp3_paths << path if File.extname(path).downcase == '.mp3'
end
puts "Found #{mp3_paths.size} MP3 files in #{destination}"

# Determine which FLAC files in the source do not have corresponding MP3 files
# in the destination.
new_flac_paths = {}
flac_paths.each do |flac_path|
  mp3_path = File.expand_path File.join(destination, flac_path.gsub(source, '').gsub('.flac', '.mp3'))
  new_flac_paths[flac_path] = mp3_path unless mp3_paths.include?(mp3_path)
end
puts "Found #{new_flac_paths.size} FLAC files that do not have MP3s."

exceptions = []
new_flac_paths.each_pair do |flac_path, mp3_path|
  begin
    puts "Converting \e[33m#{flac_path}\e[0m to \e[32m#{mp3_path}\e[0m"
    command  = "mkdir -p '#{mp3_path.gsub(File.basename(mp3_path), '')}'"
    command << " && flac -dcs '#{flac_path}' | lame --silent -V0 --vbr-new - '#{mp3_path}'"
    `#{command}`
    raise "Exit status was #{$?.exitstatus}" if $?.exitstatus != 0
  rescue Interrupt => exception
    raise exception
  rescue Exception => exception
    File.delete output if File.exists?(output)
    exceptions << exception
    puts "EXCEPTION: #{exception.class} - #{exception}"
    puts "\tBACKTRACE:\n\t\t#{exception.backtrace.join("\n\t\t")}"
  end
end