require 'rubygems/package_task'
require 'rdoc/task'
require 'bundler/setup'

RGenGemSpec = eval(File.read('rgen.gemspec'))

RDoc::Task.new do |rd|
  rd.main = 'README.rdoc'
  rd.rdoc_files.include('README.rdoc', 'CHANGELOG', 'MIT-LICENSE', 'lib/**/*.rb')
  rd.rdoc_files.exclude('lib/metamodels/*')
  rd.rdoc_files.exclude('lib/ea_support/uml13*')
  rd.rdoc_dir = 'doc'
end

RGenPackageTask = Gem::PackageTask.new(RGenGemSpec) do |p|
  p.need_zip = false
end	

task :prepare_package_rdoc => :rdoc do
  RGenPackageTask.package_files.include('doc/**/*')
end

task :release => [:prepare_package_rdoc, :package]

task :clobber => [:clobber_rdoc, :clobber_package]
