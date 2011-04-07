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

  Problem = Struct.new(:severity, :line, :message)
  def get_problems(file)
    load_model
    fragment = @model.fragments.find{|f| File.expand_path(f.location) == file}
    return [] unless fragment
    result = []
    fragment.data[:problems].each do |p|
      result << Problem.new("Error", p.line, p.message)
    end
    fragment.unresolved_refs.each do |ur|
      result << Problem.new("Error", @lang.line_number(ur.element), "unresolved reference #{ur.proxy.targetIdentifier}")
    end
    result
  end

  OpenElementChoice = Struct.new(:display_name, :file, :line)
  def get_open_element_choices(pattern)
    result = []
    sub_index = element_name_index[pattern[0..0].downcase]
    sub_index && sub_index.each_pair do |ident, elements|
      if ident.split(/\W/).last.index(pattern) == 0
        elements.each do |e|
          if @lang.fragment_ref(e)
            name = ident[ident.rindex(/\W/)+1..-1]
            scope = ident[0..ident.rindex(/\W/)-1]
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
