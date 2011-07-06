module RText

class DefaultServiceProvider

  def initialize(language, fragmented_model, model_loader)
    @lang = language
    @model = fragmented_model
    @loader = model_loader 
    @element_name_index = nil
    @model.add_fragment_change_listener(proc {|fragment, kind|
      @element_name_index = nil
    })
  end

  def load_model
    @loader.load
  end

  ReferenceCompletionOption = Struct.new(:identifier, :type)
  def get_reference_completion_options(reference, context)
    if @model.environment
      targets = @model.environment.find(:class => reference.eType.instanceClass)
    else
      clazz = reference.eType.instanceClass
      targets = @model.index.values.flatten.select{|e| e.is_a?(clazz)}
    end
    targets.collect{|t| 
      ReferenceCompletionOption.new(
        @lang.identifier_provider.call(t, context), t.class.ecore.name)}.
      sort{|a,b| a.identifier <=> b.identifier}
  end

  ReferenceTarget = Struct.new(:file, :line, :display_name)
  def get_reference_targets(identifier, context)
    result = []
    identifier = @lang.qualify_reference(identifier, context)
    targets = @model.index[identifier]
    targets && targets.each do |t|
      if @lang.fragment_ref(t)
        path = File.expand_path(@lang.fragment_ref(t).fragment.location)
        result << ReferenceTarget.new(path, @lang.line_number(t), "#{identifier} [#{t.class.ecore.name}]")
      end
    end
    result
  end

  def get_referencing_elements(identifier, context)
    result = []
    targets = @model.index[@lang.identifier_provider.call(context, nil)]
    if targets && targets.size == 1
      target = targets.first
      elements = target.class.ecore.eAllReferences.select{|r|
        r.eOpposite && !r.containment && !r.eOpposite.containment}.collect{|r|
          target.getGenericAsArray(r.name)}.flatten
      elements.each do |e|
        if @lang.fragment_ref(e)
          path = File.expand_path(@lang.fragment_ref(e).fragment.location)
          display_name = ""
          ident = @lang.identifier_provider.call(e, nil)
          display_name += "#{ident} " if ident
          display_name += "[#{e.class.ecore.name}]"
          result << ReferenceTarget.new(path, @lang.line_number(e), display_name)
        end
      end
    end
    result
  end

  FileProblems = Struct.new(:file, :problems)
  Problem = Struct.new(:severity, :line, :message)
  def get_problems
    load_model
    result = []
    duplicates_by_fragment = {}
    @model.index.each_pair do |ident, elements|
      if elements.size > 1
        elements.each do |e|
          next if e.class.ecore.name == "ARPackage"
          frag = @lang.fragment_ref(e).fragment
          duplicates_by_fragment[frag] ||= []
          duplicates_by_fragment[frag] << e
        end
      end
    end
    @model.fragments.sort{|a,b| a.location <=> b.location}.each do |fragment|
      problems = []
      if fragment.data && fragment.data[:problems]
        fragment.data[:problems].each do |p|
          problems << Problem.new("Error", p.line, p.message)
        end
      end
      fragment.unresolved_refs.each do |ur|
        # TODO: where do these proxies come from?
        next unless ur.proxy.targetIdentifier
        problems << Problem.new("Error", @lang.line_number(ur.element), "unresolved reference #{ur.proxy.targetIdentifier}")
      end
      dups = duplicates_by_fragment[fragment]
      dups && dups.each do |e|
        ident = @lang.identifier_provider.call(e, nil)
        problems << Problem.new("Error", @lang.line_number(e), "duplicate identifier #{ident}")
      end
      if problems.size > 0
        result << FileProblems.new(File.expand_path(fragment.location), problems)
      end
    end
    result
  end

  OpenElementChoice = Struct.new(:display_name, :file, :line)
  def get_open_element_choices(pattern)
    result = []
    return result unless pattern
    sub_index = element_name_index[pattern[0..0].downcase]
    sub_index && sub_index.each_pair do |ident, elements|
      if ident.split(/\W/).last.downcase.index(pattern.downcase) == 0
        elements.each do |e|
          if @lang.fragment_ref(e)
            non_word_index = ident.rindex(/\W/)
            if non_word_index
              name = ident[non_word_index+1..-1]
              scope = ident[0..non_word_index-1]
            else
              name = ident
              scope = ""
            end
            display_name = "#{name} [#{e.class.ecore.name}]"
            display_name += " - #{scope}" if scope.size > 0
            path = File.expand_path(@lang.fragment_ref(e).fragment.location)
            result << OpenElementChoice.new(display_name, path, @lang.line_number(e))
          end
        end
      end
    end
    result.sort{|a,b| a.display_name <=> b.display_name}
  end

  def element_name_index
    return @element_name_index if @element_name_index
    @element_name_index = {}
    @model.index.each_pair do |ident, elements|
      key = ident.split(/\W/).last[0..0].downcase
      @element_name_index[key] ||= {} 
      @element_name_index[key][ident] = elements
    end
    @element_name_index
  end

end

end
