$:.unshift File.join(File.dirname(__FILE__),"..")

require 'ea/xmi_class_instantiator'
require 'mmgen/metamodel_generator'

include MMGen::MetamodelGenerator

unless ARGV.length >= 2
	puts "Usage: mmgen.rb <xmi_class_model_file> <root package> (<module>)*"
	exit
else
	file_name = ARGV.shift
	root_package_name = ARGV.shift
	modules = ARGV
	out_file = file_name.gsub(/\.\w+$/,'.rb')
	puts out_file
end

envUML = RGen::Environment.new
File.open(file_name) { |f|
	XMIClassInstantiator.new.instantiateUMLClassModel(envUML, f.read)
}

rootPackage = envUML.find(:class => UMLClassModel::UMLPackage).select{|p| p.name == root_package_name}.first

generateMetamodel(rootPackage, out_file, modules)
