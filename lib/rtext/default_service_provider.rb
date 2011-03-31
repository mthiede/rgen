module RText

class DefaultServiceProvider

  def initialize(language, fragmented_model, model_loader)
    @lang = language
    @model = fragmented_model
    @loader = model_loader 
  end

  def load_model
    @loader.load
  end

  ReferenceCompletionOption = Struct.new(:identifier, :type)
  def get_reference_completion_options(reference, context)
    if @model.environment
      targets = @model.environment.find(:class => reference.eType.instanceClass)
    else
      targets = @model.index.values.flatten.select{|e| e.is_a?(reference.eType.instanceClass)}
    end
    targets.collect{|t| 
      ReferenceCompletionOption.new(
        @lang.identifier_provider.call(t, context), t.class.ecore.name)}.
      sort{|a,b| a.identifier <=> b.identifier}
  end

  ReferenceTarget = Struct.new(:file, :line)
  def get_reference_targets(identifier, context)
    result = []
    identifier = @lang.qualify_reference(identifier, context)
    targets = @model.index[identifier]
    targets && targets.each do |e|
      if @lang.file_name(e)
        result << ReferenceTarget.new(@lang.file_name(e), @lang.line_number(e))
      end
    end
    result
  end

  Problem = Struct.new(:severity, :line, :message)
  def get_problems(file)
    load_model
    fragment = @model.fragments.find{|f| f.location == file}
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
    @model.index.each_pair do |ident, elements|
      if ident.split(/\W/).any?{|p| p.index(pattern) == 0}
        elements.each do |e|
          if @lang.file_name(e)
            result << OpenElementChoice.new("#{ident} [#{e.class.ecore.name}]",
              @lang.file_name(e), @lang.line_number(e))
          end
        end
      end
    end
    result.sort{|a,b| a.display_name <=> b.display_name}
  end

end

end
