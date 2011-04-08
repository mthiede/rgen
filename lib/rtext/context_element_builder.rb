module RText

module ContextElementBuilder

  class << self

  def build_context_element(language, context_lines, position_in_line)
    context_info = fix_context(context_lines)
    return nil unless context_info
    element = instantiate_context_element(language, context_info)
    unless element
      fix_current_line(context_info, position_in_line)
      element = instantiate_context_element(language, context_info)
    end
    element
  end

  private

  def instantiate_context_element(language, context_info)
    root_elements = []
    problems = []
    Instantiator.new(language).instantiate(context_info.lines.join("\n"),
      :root_elements => root_elements, :problems => problems)
    if root_elements.size > 0
      find_leaf_child(root_elements.first, context_info.num_elements-1)
    else
      nil
    end
  end

  def find_leaf_child(element, num_required_children)
    childs = element.class.ecore.eAllReferences.select{|r| r.containment}.collect{|r|
      element.getGenericAsArray(r.name)}.flatten
    if childs.size > 0
      find_leaf_child(childs.first, num_required_children-1)
    elsif num_required_children == 0
      element
    else
      nil
    end
  end

  ContextInfo = Struct.new(:lines, :num_elements, :pos_leaf_element)

  def fix_context(context_lines)
    context_lines = context_lines.dup
    line = context_lines.last
    return nil if line.nil? || is_non_element_line(line)
    context_lines << strip_curly_brace(context_lines.pop)
    pos_leaf_element = context_lines.size-1
    num_elements = 1
    context_lines.reverse.each do |l|
      if l =~ /\{\s*$/
        context_lines << "}"
        num_elements += 1
      elsif l =~ /\[\s*$/
        context_lines << "]"
      end
    end
    ContextInfo.new(context_lines, num_elements, pos_leaf_element)
  end

  def is_non_element_line(line)
    line = line.strip
    line == "" || line == "}" || line == "]" || line =~ /^#/ || line =~ /^\w+:$/
  end

  def strip_curly_brace(line)
    line.sub(/\{\s*$/,'') 
  end

  def fix_current_line(context_info, pos_in_line)
    context_info.lines[context_info.pos_leaf_element] = 
      cut_current_argument(context_info.lines[context_info.pos_leaf_element], pos_in_line)
  end

  def cut_current_argument(line, pos_in_line)
    left_comma_pos = line.rindex(",", pos_in_line-1)
    if left_comma_pos
      line[0..left_comma_pos-1]
    elsif line =~ /^\s*\w+/
      $&
    else
      ""
    end
  end

  end

end

end

