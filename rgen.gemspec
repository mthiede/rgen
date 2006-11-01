require 'rubygems'

SPEC = Gem::Specification.new do |s|
  s.name = %q{rgen}
  s.version = "0.3.0"
  s.date = %q{2006-10-08}
  s.summary = %q{Ruby Modelling and Generator Framework}
#  s.email = %q{}
#  s.homepage = %q{}
  s.rubyforge_project = %q{rgen}
  s.description = %q{RGen is a framework supporting Model Driven Software Development (MDSD). This means that it helps you build Metamodels, instantiate Models, modify and transform Models and finally generate arbitrary textual content from it.}
#  s.autorequire = %q{}
  s.has_rdoc = true
  s.authors = ["Martin Thiede"]
  candidates = Dir.glob("{lib,test}/**/*")
  s.files = candidates.delete_if do |item|
  	item.include?(".svn") || item.include?(".settings")
  end
  s.rdoc_options = ["--main", "README"]
  s.extra_rdoc_files = ["README", "CHANGELOG", "MIT-LICENSE"]
end
