abort 'Use the rake task to build the gem' if $0 =~ /gem$/ && $*.first == 'build'

Gem::Specification.new do |s|
  s.name = %q{rgen}
  s.version = '0.8.3'
  s.date = Time.now.strftime('%Y-%m-%d')
  s.summary = %q{Ruby Modelling and Generator Framework}
  s.email = %q{martin dot thiede at gmx de}
  s.homepage = %q{http://ruby-gen.org}
  s.rubyforge_project = %q{rgen}
  s.description = %q{RGen is a framework for Model Driven Software Development (MDSD) in Ruby. This means that it helps you build Metamodels, instantiate Models, modify and transform Models and finally generate arbitrary textual content from it.}
  s.authors = ['Martin Thiede']
  s.rdoc_options = %w(--main README.rdoc -x test -x metamodels -x ea_support/uml13*)
  s.extra_rdoc_files = %w(README.rdoc CHANGELOG MIT-LICENSE)
  s.files = Dir.glob(File.join('lib', '**', '*')) + Dir.glob(File.join('test', '**', '*')) +
      %w(README.rdoc CHANGELOG MIT-LICENSE Rakefile) - Dir.glob(File.join('**', '*.bak'))
  s.add_dependency 'nokogiri', '~> 1.6', '>= 1.6.8.1'
  s.add_development_dependency 'minitest', '~> 5.10', '>= 5.10.1'
end