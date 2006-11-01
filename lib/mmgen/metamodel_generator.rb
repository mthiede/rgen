require 'rgen/environment'
require 'rgen/template_language'
require 'uml/uml_classmodel'
require 'mmgen/mm_ext/uml_classmodel_ext'

module MMGen

module MetamodelGenerator

	def generateMetamodel(rootPackage, out_file, modules=[])
		tc = RGen::TemplateLanguage::DirectoryTemplateContainer.new(UMLClassModel, File.dirname(out_file))
		tpl_path = File.dirname(__FILE__) + '/templates'
		tc.load(tpl_path)
		tc.expand('uml_classmodel::GenerateClassModel', File.basename(out_file), modules, :for => rootPackage)
	end

end

end