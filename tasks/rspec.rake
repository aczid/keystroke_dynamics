begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  require 'spec'
end
begin
  require 'spec/rake/spectask'
  require 'spec/rake/verify_rcov'
rescue LoadError
  puts <<-EOS
To use rspec for testing you must install rspec gem:
    gem install rspec
EOS
  exit(0)
end
require 'rcov'

desc "Run the specs under spec/models"
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "spec/spec.opts"]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

desc "Run all specs with rcov and store coverage report in doc/output/coverage"
Spec::Rake::SpecTask.new(:spec_rcov) do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.rcov = true
  t.rcov_dir = 'doc/output/coverage'
  t.rcov_opts = ['--exclude', 'spec,\.autotest']
end

desc "Verify that coverage is 100%"
RCov::VerifyTask.new(:verify_rcov => :spec_rcov) do |t|
  t.index_html = "doc/output/coverage/index.html"
  t.threshold = 100
end
