require 'rubygems/package_task'
require 'rdoc/task'
require 'rake/testtask'

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

::Rake::TestTask.new(:test) do |t|
  t.test_files = ['test/rgen_test.rb']
  t.warning = false
end

task :prepare_package_rdoc => :rdoc do
  RGenPackageTask.package_files.include('doc/**/*')
end

task :release => [:prepare_package_rdoc, :package]

task :clobber => [:clobber_rdoc, :clobber_package]

task :ecore_to_json do
  require 'rgen/ecore/ecore_to_json'

  exporter = RGen::ECore::ECoreToJson.new
  File.write('ecore.json', exporter.epackage_to_json_string(RGen.ecore, exporter.ecore_datatypes))
end
