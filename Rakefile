require 'rake/gempackagetask'
require 'rake/rdoctask'

RGenGemSpec = Gem::Specification.new do |s|
  s.name = %q{rgen}
  s.version = "0.5.1"
  s.date = %q{2009-11-10}
  s.summary = %q{Ruby Modelling and Generator Framework}
  s.email = %q{martin dot thiede at gmx de}
  s.homepage = %q{ruby-gen.org}
  s.rubyforge_project = %q{rgen}
  s.description = %q{RGen is a framework supporting Model Driven Software Development (MDSD). This means that it helps you build Metamodels, instantiate Models, modify and transform Models and finally generate arbitrary textual content from it.}
  s.has_rdoc = true
  s.authors = ["Martin Thiede"]
  gemfiles = Rake::FileList.new
  gemfiles.include("{lib,test,redist}/**/*")
  gemfiles.include("README", "CHANGELOG", "MIT-LICENSE", "Rakefile") 
  gemfiles.exclude(/\b\.bak\b/)
  s.files = gemfiles
  s.rdoc_options = ["--main", "README", "-x", "redist", "-x", "test", "-x", "metamodels", "-x", "ea_support/uml13*"]
  s.extra_rdoc_files = ["README", "CHANGELOG", "MIT-LICENSE"]
end

Rake::RDocTask.new do |rd|
  rd.main = "README"
  rd.rdoc_files.include("README", "CHANGELOG", "MIT-LICENSE", "lib/**/*.rb")
  rd.rdoc_files.exclude("lib/metamodels")
  rd.rdoc_files.exclude("lib/ea_support/uml13*")
  rd.rdoc_dir = "doc"
end

RGenPackageTask = Rake::GemPackageTask.new(RGenGemSpec) do |p|
  p.need_zip = true
end	

task :publish_doc do
  sh %{pscp -r doc/* thiedem@rubyforge.org:/var/www/gforge-projects/rgen}
end

task :prepare_package_rdoc => :rdoc do
  RGenPackageTask.package_files.include("doc/**/*")
end

task :release => [:prepare_package_rdoc, :package]

task :clobber => [:clobber_rdoc, :clobber_package]
