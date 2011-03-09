require 'rgen/ecore/ecore_ext'

module RText

class Completer

  CompletionOption = Struct.new(:text, :extra)

  # Creates a completer for RText::Language +language+.
  #
  def initialize(language)
    @lang = language
  end

  # Provides completion options
  #
  #  +linestart+ 
  #    the content of the current line before the cursor
  #
  #  +prev_line_provider+ 
  #    is a proc which must return lines above the current line
  #    it receives an index parameter in the range 1..n
  #    1 is the line just above the current one, 2 is the second line above, etc.
  #    the proc must return the line as a string or nil if there is no more line
  #
  def complete(linestart, prev_line_provider)
    # command
    if linestart =~ /^\s*(\w*)$/ 
      prefix = $1
      classes = completion_classes(prev_line_provider)
      classes = classes.select{|c| c.name.index(prefix) == 0} if prefix
      classes.sort{|a,b| a.name <=> b.name}.collect do |c| 
        uargs = @lang.unlabled_arguments(c).collect{|a| "<#{a.name}>"}.join(", ")
        CompletionOption.new(c.name, uargs)
      end
    # attribute
    elsif linestart =~ /^\s*(\w+)\s+(?:[^,]+,)*\s*(\w*)$/
      command, prefix = $1, $2
      clazz = @lang.root_epackage.eAllClasses.find{|c| c.name == command}
      if clazz
        features = @lang.labled_arguments(clazz)
        features = features.select{|f| f.name.index(prefix) == 0} if prefix
        features.sort{|a,b| a.name <=> b.name}.collect do |f| 
          CompletionOption.new("#{f.name}:", "<#{f.eType.name}>")
        end
      else
        []
      end
    else
      []
    end
  end

  private

  def completion_classes(prev_line_provider)
    clazz, feature = context(prev_line_provider)
    if clazz
      if feature
        @lang.concrete_types(feature.eType)
      else
        refs_by_class = {}
        clazz.eAllReferences.select{|r| r.containment}.each do |r|
          @lang.concrete_types(r.eType).each { |c| (refs_by_class[c] ||= []) << r }
        end
        refs_by_class.keys.select{|c| refs_by_class[c].size == 1}
      end
    else
      @lang.root_epackage.eAllClasses.select{|c| !c.abstract &&
        !c.eAllReferences.any?{|r| r.eOpposite && r.eOpposite.containment}}
    end
  end

  def context(prev_line_provider)
    command, role = parse_context(prev_line_provider)
    clazz = command && @lang.root_epackage.eAllClasses.find{|c| c.name == command}
    feature = role && clazz && clazz.eAllReferences.find{|r| r.containment && r.name == role}
    [clazz, feature]
  end

  def parse_context(prev_line_provider)
    block_nesting = 0
    array_nesting = 0
    non_empty_lines = 0
    role = nil
    i = 0
    while line = prev_line_provider.call(i+=1)
      # empty or comment
      next if line =~ /^\s*$/ || line =~ /^\s*#/
      # role
      if line =~ /^\s*(\w+):\s*$/
        role = $1 if non_empty_lines == 0
      # block open
      elsif line =~ /^\s*(\S+).*\{\s*$/
        block_nesting -= 1
        return [$1, role] if block_nesting < 0
      # block close
      elsif line =~ /^\s*\}\s*$/
        block_nesting += 1
      # array open
      elsif line =~ /^\s*(\w+):\s*\[\s*$/
        array_nesting -= 1
        role = $1 if array_nesting < 0
      # array close
      elsif line =~ /^\s*\]\s*$/
        array_nesting += 1
      end
      non_empty_lines += 1
    end
    [nil, nil]
  end

end

end

