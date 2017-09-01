require "bundler"
Bundler::GemHelper.install_tasks

require "rake/testtask"
require "fileutils"

Rake::TestTask.new(:test) do |t|
  if File.exists? "stub_server.log"
    puts "clear stub_server.log"
    FileUtils.rm "stub_server.log"
  end

  t.libs.push("lib", "test")
  t.test_files = FileList["test/**/test_*.rb"]
  t.verbose = true
  t.warning = true
end

task default: [:test]
