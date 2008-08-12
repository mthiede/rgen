require 'rubygems'

SPEC = Gem::Specification.new do |s|
  s.name = %q{rgen}
  s.version = "0.4.3"
  s.date = %q{2008-08-12}
  s.summary = %q{Ruby Modelling and Generator Framework}
#  s.email = %q{}
#  s.homepage = %q{}
  s.rubyforge_project = %q{rgen}
  s.description = %q{RGen is a framework supporting Model Driven Software Development (MDSD). This means that it helps you build Metamodels, instantiate Models, modify and transform Models and finally generate arbitrary textual content from it.}
#  s.autorequire = %q{}
  s.has_rdoc = true
  s.authors = ["Martin Thiede"]
  candidates = Dir.glob("{lib,test,redist}/**/*")
  s.files = candidates.delete_if do |item|
  	item.include?(".svn") || item.include?(".settings")
  end
  s.rdoc_options = ["--main", "README", "-x", "redist", "-x", "test", "-x", "metamodels"]
  s.extra_rdoc_files = ["README", "CHANGELOG", "MIT-LICENSE"]
#  s.require_path = ["lib", "redist/xmlscan/lib"]
end
