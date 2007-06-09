$:.unshift File.join(File.dirname(__FILE__),"..","lib")
$:.unshift File.join(File.dirname(__FILE__),"..","test")

require 'test/unit'
require 'rgen/environment'
require 'rgen/transformer'
require 'rgen/instantiator/xmi_instantiator'
require 'metamodels/uml13_metamodel'
require 'ea/uml13_to_ecore'
require 'mmgen/metamodel_generator'

class XmiInstantiatorTest < Test::Unit::TestCase

	include MMGen::MetamodelGenerator

#	MODEL = File.join(File.dirname(__FILE__),"xmi_instantiator_test/testmodel.xml")
    MODEL = "d:/workspace_mod/orpheus_instantiator/model2.xml"
	OUT_FILE = File.join(File.dirname(__FILE__),"xmi_instantiator_test/generated.rb")

	def test_model
	  #TODO add element names to make feature names unique
        fix_map = {
          :tag_map => {
            "EAStub" => proc {|tag, attr| 
              c = UML13::Class.new
              c.name = attr["name"]
              c
            }
          },
          :feature_names => {
            "isOrdered" => "ordering",
            "subtype" => "child",
            "supertype" => "parent",
            "changeable" => "changeability"
          },
          :feature_values => {
            "ordering" => {"true" => "ordered", "false" => "unordered"},
            "changeability" => {"none" => "frozen"},
            "multiplicity" => proc { |v|
              mult = UML13::Multiplicity.new
              multrange = UML13::MultiplicityRange.new
              mult.addRange(multrange)
              multrange.lower = v.split("..").first
              multrange.upper = v.split("..").last
              mult
            }
          }
        }
		envUML = RGen::Environment.new
		File.open(MODEL) { |f|
			inst = XMIInstantiator.new(envUML, fix_map, XMIInstantiator::WARN)
			inst.add_metamodel("omg.org/UML1.3", UML13)
			inst.instantiate(f.read)
		}

        envECore = RGen::Environment.new
		rootPackage = UML13ToECore.new(envUML,envECore).trans envUML.find(:class => UML13::Package).first
		
		envECore.find(:class => RGen::ECore::EClass).each do |c|
		  if c.name =~ /(\w+)\s*(\{[^\}]+\})/
            puts $2
            c.name = $1
          end
        end

		envECore.find(:class => RGen::ECore::EStructuralFeature).each do |f|
		  if f.name =~ /(\w+)\s*\{([^\}]+)\}/
            puts $2
            name, tags = $1, $2.split(',').collect{|t| t.strip}
            f.derived = true if tags.include?("derived")
            f.name = name
          end
        end
        
		generateMetamodel(rootPackage, OUT_FILE)
		
		
#		UML13.ecore.eClassifiers.each do |c|
#          puts c.name+": "+c.eAllSuperTypes.name.inspect
#        end

	end


end