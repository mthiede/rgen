require 'rgen/transformer'
require 'metamodels/uml13_metamodel'
require 'ea_support/uml13_ea_metamodel'

class UML13EAToUML13 < RGen::Transformer
  include UML13EA
  
  def transform
    trans(:class => Package)
    trans(:class => Class)
  end
  
  def cleanModel
    @env_out.find(:class => UML13::ModelElement).each do |me|
      me.taggedValue = []
    end
  end
  
  copy_all UML13EA, :to => UML13, :except => %w(
    XmiIdProvider
    AssociationEnd AssociationEndRole
    StructuralFeature
    Generalization
    ActivityModel 
    CompositeState 
    PseudoState
  )  
    
  transform AssociationEndRole, :to => UML13::AssociationEndRole do
    copyAssociationEnd
  end

  transform AssociationEnd, :to => UML13::AssociationEnd do
    copyAssociationEnd
  end
  
  def copyAssociationEnd
    copy_features :except => [:isOrdered, :changeable] do
      {:ordering => isOrdered ? :ordered : :unordered,
       :changeability => {:none => :frozen}[changeable] || changeable,
       :aggregation => {:shared => :aggregate}[aggregation] || aggregation,
       :multiplicity => UML13::Multiplicity.new(
        :range => [UML13::MultiplicityRange.new(
          :lower => multiplicity && multiplicity.split("..").first,
          :upper => multiplicity && multiplicity.split("..").last)])}
    end
  end

  transform StructuralFeature, :to => UML13::StructuralFeature do
    copy_features :except => [:changeable] do
      {:changeability => {:none => :frozen}[changeable] }
    end
  end

  transform Generalization, :to => UML13::Generalization do
    copy_features :except => [:subtype, :supertype] do 
      { :child => trans(subtype),
        :parent => trans(supertype) }
    end
  end
  
  copy ActivityModel, :to => UML13::ActivityGraph

  transform CompositeState, :to => UML13::CompositeState do
    copy_features :except => [:substate] do
      { :subvertex => trans(substate) }
    end
  end
  
  copy PseudoState, :to => UML13::Pseudostate
  
end