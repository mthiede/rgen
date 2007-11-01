require 'rgen/instantiator/xmi11_instantiator'
require 'metamodels/uml13_metamodel'

class EAInstantiator < XMI11Instantiator

  #TODO add element names to make feature names unique
  FIXMAP = {
    :tags => {
      "EAStub" => proc { |tag, attr| UML13::Class.new(
        :name => attr["name"]
      )},
      "ActivityModel" => "ActivityGraph",
      "PseudoState" => "Pseudostate"
    },
    :feature_names => {
      "isOrdered" => "ordering",
      "subtype" => "child",
      "supertype" => "parent",
      "changeable" => "changeability",
      "substate" => "subvertex"
    },
    :feature_values => {
      "ordering" => {"true" => "ordered", "false" => "unordered"},
      "aggregation" => {"shared" => "aggregate"},
      "changeability" => {"none" => "frozen"},
      "multiplicity" => proc { |v| UML13::Multiplicity.new(
        :range => [UML13::MultiplicityRange.new(
          :lower => v.split("..").first,
          :upper => v.split("..").last
        )])}
    }
  }
  
  def initialize(env, loglevel)
    super(env, FIXMAP, loglevel)
    add_metamodel("omg.org/UML1.3", UML13)
  end
  
end
