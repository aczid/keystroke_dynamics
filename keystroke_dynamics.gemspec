# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{keystroke_dynamics}
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aram Verstegen"]
  s.date = %q{2009-04-18}
  s.description = %q{Simple keystroke dynamics analyzer/validator written in Ruby-GTK}
  s.email = ["aram@aczid.nl"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc"]
  s.files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "examples/enroll_login.rb", "examples/enroll_sentences.rb", "examples/login.rb", "lib/keystroke_dynamics.rb", "lib/keystroke_dynamics/analysis.rb", "lib/keystroke_dynamics/validation.rb", "script/console", "script/destroy", "script/generate", "spec/keystroke_dynamics_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "tasks/rspec.rake"]
  s.has_rdoc = true
  s.homepage = %q{http://ksd.rubyforge.org/}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{keystroke_dynamics}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Simple keystroke dynamics analyzer/validator written in Ruby-GTK}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<newgem>, [">= 1.3.0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<newgem>, [">= 1.3.0"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<newgem>, [">= 1.3.0"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
