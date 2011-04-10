$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")

require 'test/unit'
require 'rgen/environment'
require 'rgen/metamodel_builder'
require 'rtext/instantiator'
require 'rtext/language'

class RTextInstantiatorTest < Test::Unit::TestCase

  module TestMM
    extend RGen::MetamodelBuilder::ModuleExtension
    class TestNode < RGen::MetamodelBuilder::MMBase
      SomeEnum = RGen::MetamodelBuilder::DataTypes::Enum.new([:A, :B])
      has_attr 'text', String
      has_attr 'integer', Integer
      has_attr 'boolean', Boolean
      has_attr 'enum', SomeEnum
      has_many_attr 'nums', Integer
      has_attr 'float', Float
      has_one 'related', TestNode
      has_many 'others', TestNode
      contains_many 'childs', TestNode, 'parent'
    end
  end

  module TestMM2
    extend RGen::MetamodelBuilder::ModuleExtension
    class TestNode < RGen::MetamodelBuilder::MMBase
      contains_one 'singleChild', TestNode, 'parent'
    end
    class TestNode2 < RGen::MetamodelBuilder::MMBase
    end
    class TestNode3 < RGen::MetamodelBuilder::MMBase
    end
    class TestNode4 < TestNode
    end
    TestNode.contains_one 'singleChild2a', TestNode2, 'parentA'
    TestNode.contains_one 'singleChild2b', TestNode2, 'parentB'
  end

  module TestMMLinenoFilename
    extend RGen::MetamodelBuilder::ModuleExtension
    class TestNode < RGen::MetamodelBuilder::MMBase
      has_attr 'text', String
      has_attr 'lineno', Integer
      has_attr 'filename', String
      contains_many 'childs', TestNode, 'parent'
    end
  end

  module TestMMAbstract
    extend RGen::MetamodelBuilder::ModuleExtension
    class TestNode < RGen::MetamodelBuilder::MMBase
      abstract
    end
  end

  module TestMMData
    extend RGen::MetamodelBuilder::ModuleExtension
    # class "Data" exists in the standard Ruby namespace
    class Data < RGen::MetamodelBuilder::MMBase
      has_attr 'notTheBuiltin', String
    end
  end

  module TestMMSubpackage
    extend RGen::MetamodelBuilder::ModuleExtension
    module SubPackage
      extend RGen::MetamodelBuilder::ModuleExtension
      class TestNodeSub < RGen::MetamodelBuilder::MMBase
        has_attr 'text', String
      end
      class Data < RGen::MetamodelBuilder::MMBase
        has_attr 'notTheBuiltin', String
      end
    end
  end

  def test_simple
    env, problems = instantiate(%Q(
      TestNode text: "some text", nums: [1,2] {
        TestNode text: "child"
        TestNode text: "child2"
      }
      ), TestMM)
    assert_no_problems(problems)
    assert_model_simple(env, :with_nums)
  end

  def test_multiple_roots
    env, problems = instantiate(%Q(
      TestNode
      TestNode
    ), TestMM)
    assert_no_problems(problems)
    assert_equal 2, env.elements.size
  end

  def test_comment
    env, problems = instantiate(%Q(
      # comment 1
      TestNode text: "some text" {
        childs: [
          # comment 2
          TestNode text: "child"
          # comment 3
          TestNode text: "child2"
        ]
      }
      ), TestMM)
    assert_no_problems(problems)
    assert_model_simple(env)
  end

  # 
  # options
  # 

  def test_line_number_setter
    env, problems = instantiate(%q(
      TestNode text: "node1" {
        TestNode text: "node2"

        #some comment
        TestNode text: "node3"
      }
      TestNode text: "node4"
    ), TestMMLinenoFilename, :line_number_attribute => "lineno")
    assert_no_problems(problems)
    assert_equal 2, env.find(:text => "node1").first.lineno
    assert_equal 3, env.find(:text => "node2").first.lineno
    assert_equal 6, env.find(:text => "node3").first.lineno
    assert_equal 8, env.find(:text => "node4").first.lineno
  end

  def test_root_elements
    root_elements = []
    env, problems = instantiate(%Q(
      TestNode text: A
      TestNode text: B
      TestNode text: C
    ), TestMM, :root_elements => root_elements)
    assert_no_problems(problems)
    assert_equal ["A", "B", "C"], root_elements.text
  end

  def test_file_name_option
    env, problems = instantiate(%Q(
      TestNode text: A
      TestNode text: B
      TestNode a problem here 
    ), TestMM, :file_name => "some_file")
    assert_equal ["some_file"], problems.collect{|p| p.file}
  end

  def test_file_name_setter
    env, problems = instantiate(%Q(
      TestNode text: A
    ), TestMMLinenoFilename, :file_name => "some_file", :file_name_attribute => "filename")
    assert_equal "some_file", env.elements.first.filename 
  end

  #
  # children with role
  #

  def test_child_role
    env, problems = instantiate(%Q(
      TestNode text: "some text" {
        TestNode text: "child"
        childs:
          TestNode text: "child2"
      }
      ), TestMM)
    assert_no_problems(problems)
    assert_model_simple(env)
  end

  def test_child_role2
    env, problems = instantiate(%Q(
      TestNode text: "some text" {
        childs: [
          TestNode text: "child"
          TestNode text: "child2"
        ]
      }
      ), TestMM)
    assert_no_problems(problems)
    assert_model_simple(env)
  end

  def test_child_role3
    env, problems = instantiate(%Q(
      TestNode text: "some text" {
        childs:
          TestNode text: "child"
        childs:
          TestNode text: "child2"
      }
      ), TestMM)
    assert_no_problems(problems)
    assert_model_simple(env)
  end

  def test_child_role4
    env, problems = instantiate(%Q(
      TestNode text: "some text" {
        childs: [
          TestNode text: "child"
        ]
        childs: [
          TestNode text: "child2"
        ]
      }
      ), TestMM)
    assert_no_problems(problems)
    assert_model_simple(env)
  end

  #
  # whitespace
  # 

  def test_whitespace1
    env, problems = instantiate(%Q(
      TestNode    text:  "some text" , nums: [ 1 , 2 ] {

        # comment

        TestNode text: "child"

        TestNode text: "child2"

      }
      ), TestMM)
    assert_no_problems(problems)
    assert_model_simple(env, :with_nums)
  end

  def test_whitespace2
    env, problems = instantiate(%Q(
      # comment1

      # comment2

      TestNode    text:  "some text"  {

        childs:

        # comment

        TestNode text: "child"

        childs:  [

        TestNode text: "child2"

        ]

      }
      ), TestMM)
    assert_no_problems(problems)
    assert_model_simple(env)
  end

  #
  # references
  # 

  def test_references
    unresolved_refs = []
    env, problems = instantiate(%Q(
      TestNode text: "root" {
        TestNode related: /
        TestNode related: //
        TestNode related: /some
        TestNode related: //some
        TestNode related: /some/
        TestNode related: some/
        TestNode related: some//
        TestNode related: some
        TestNode related: /some/reference
        TestNode related: /some/reference/
        TestNode related: some/reference/
        TestNode related: some/reference
      }
    ), TestMM, :unresolved_refs => unresolved_refs)
    assert_no_problems(problems)
    ref_targets = [ 
      "/",
      "//",
      "/some",
      "//some",
      "/some/",
      "some/",
      "some//",
      "some",
      "/some/reference",
      "/some/reference/",
      "some/reference/",
      "some/reference"
    ]
    assert_equal ref_targets, env.find(:text => "root").first.childs.collect{|c| c.related.targetIdentifier}
    assert_equal ref_targets, unresolved_refs.collect{|ur| ur.proxy.targetIdentifier}
  end

  def test_references_many
    env, problems = instantiate(%Q(
      TestNode text: "root" {
        TestNode others: /other
        TestNode others: [ /other ]
        TestNode others: [ /other1, /other2 ]
      }
    ), TestMM)
    assert_no_problems(problems)
    assert_equal [ 
      [ "/other" ],
      [ "/other" ],
      [ "/other1", "/other2" ],
    ], env.find(:text => "root").first.childs.collect{|c| c.others.collect{|p| p.targetIdentifier}}
  end

  def test_reference_regexp
    env, problems = instantiate(%Q(
      TestNode text: "root" {
        TestNode related: some
        TestNode related: ::some
        TestNode related: some::reference
        TestNode related: ::some::reference
      }
    ), TestMM, :reference_regexp => /\A\w*(::\w*)+/)
    assert_no_problems(problems)
    assert_equal [ 
      "some",
      "::some",
      "some::reference",
      "::some::reference"
     ], env.find(:text => "root").first.childs.collect{|c| c.related.targetIdentifier}
  end

  #
  # unlabled arguments
  # 

  def test_unlabled_arguments
    env, problems = instantiate(%Q(
      TestNode "some text", [1,2] {
        TestNode "child"
        TestNode "child2"
      }
      ), TestMM, :unlabled_arguments => proc {|clazz| ["text", "nums"]})
    assert_no_problems(problems)
    assert_model_simple(env, :with_nums)
  end

  def test_unlabled_arguments_not_in_front
    env, problems = instantiate(%Q(
      TestNode nums: [1,2], "some text" {
        TestNode "child"
        TestNode "child2"
      }
      ), TestMM, :unlabled_arguments => proc {|clazz| ["text", "nums"]})
    assert_no_problems(problems)
    assert_model_simple(env, :with_nums)
  end

  def test_unlabled_arguments_using_labled
    env, problems = instantiate(%Q(
      TestNode text: "some text", nums: [1,2] {
        TestNode text: "child"
        TestNode text: "child2"
      }
      ), TestMM, :unlabled_arguments => proc {|clazz| ["text", "nums"]})
    assert_no_problems(problems)
    assert_model_simple(env, :with_nums)
  end

  #
  # problems
  # 

  def test_unexpected_end_of_file
    env, problems = instantiate(%Q(
      TestNode text: "some text" {
    ), TestMM)
    assert_problems([/unexpected end of file, expected identifier/i], problems)
  end

  def test_unknown_command
    env, problems = instantiate(%Q(
      NotDefined 
    ), TestMM)
    assert_problems([/unknown command 'NotDefined'/i], problems)
  end

  def test_unknown_command_abstract
    env, problems = instantiate(%Q(
      TestNode
    ), TestMMAbstract)
    assert_problems([/unknown command 'TestNode'.*abstract/i], problems)
  end

  def test_unexpected_unlabled_argument
    env, problems = instantiate(%Q(
      TestNode "more text"
    ), TestMM)
    assert_problems([/unexpected unlabled argument, 0 unlabled arguments expected/i], problems)
  end

  def test_unknown_child_role
    env, problems = instantiate(%Q(
      TestNode {
        notdefined:
          TestNode
      }
    ), TestMM)
    assert_problems([/unknown child role 'notdefined'/i], problems)
  end

  def test_not_a_child_role
    env, problems = instantiate(%Q(
      TestNode {
        text:
          TestNode
        others:
          TestNode
      }
    ), TestMM)
    assert_problems([
      /role 'text' can not take child elements/i,
      /role 'others' can not take child elements/i
    ], problems)
  end

  def test_not_a_single_child
    env, problems = instantiate(%Q(
      TestNode {
        singleChild: [
          TestNode
          TestNode
        ]
      }
    ), TestMM2)
    assert_problems([
      /only one child allowed in role 'singleChild'/i,
    ], problems)
  end

  def test_not_a_single_child2
    env, problems = instantiate(%Q(
      TestNode {
        singleChild:
          TestNode
        singleChild:
          TestNode
      }
    ), TestMM2)
    assert_problems([
      /only one child allowed in role 'singleChild'/i,
    ], problems)
  end

  def test_wrong_child_role
    env, problems = instantiate(%Q(
      TestNode {
        singleChild:
          TestNode2
      }
    ), TestMM2)
    assert_problems([
      /role 'singleChild' can not take a TestNode2, expected TestNode/i,
    ], problems)
  end

  def test_wrong_child
    env, problems = instantiate(%Q(
      TestNode {
        TestNode3
      }
    ), TestMM2)
    assert_problems([
      /this kind of element can not be contained here/i,
    ], problems)
  end

  def test_ambiguous_child_role
    env, problems = instantiate(%Q(
      TestNode {
        TestNode2
      }
    ), TestMM2)
    assert_problems([
      /role of element is ambiguous, use a role label/i,
    ], problems)
  end

  def test_non_ambiguous_child_role_subclass
    env, problems = instantiate(%Q(
      TestNode {
        TestNode4
      }
    ), TestMM2)
    assert_no_problems(problems)
  end

  def test_not_a_single_child3
    env, problems = instantiate(%Q(
      TestNode {
        TestNode
        TestNode
      }
    ), TestMM2)
    assert_problems([
      /only one child allowed in role 'singleChild'/i,
    ], problems)
  end

  def test_unknown_argument
    env, problems = instantiate(%Q(
      TestNode unknown: "some text"
    ), TestMM)
    assert_problems([/unknown argument 'unknown'/i], problems)
  end

  def test_attribute_in_child_reference
    env, problems = instantiate(%Q(
      TestNode singleChild: "some text"
    ), TestMM2)
    assert_problems([/argument 'singleChild' can only take child elements/i], problems)
  end

  def test_arguments_duplicate
    env, problems = instantiate(%Q(
      TestNode text: "some text", text: "more text"
    ), TestMM)
    assert_problems([/argument 'text' already defined/i], problems)
  end

  def test_unlabled_arguments_duplicate
    env, problems = instantiate(%Q(
      TestNode text: "some text", "more text"
    ), TestMM, :unlabled_arguments => proc {|c| ["text"]})
    assert_problems([/argument 'text' already defined/i], problems)
  end

  def test_multiple_arguments_in_non_many_attribute
    env, problems = instantiate(%Q(
      TestNode text: ["text1", "text2"]
    ), TestMM)
    assert_problems([/argument 'text' can take only one value/i], problems)
  end

  def test_wrong_argument_type
    env, problems = instantiate(%Q(
      TestNode text: 1 
      TestNode integer: "text" 
      TestNode integer: true 
      TestNode integer: 1.2 
      TestNode integer: a 
      TestNode integer: /a 
      TestNode enum: 1 
      TestNode enum: x 
      TestNode related: 1
    ), TestMM)
    assert_problems([
      /argument 'text' can not take a integer, expected string/i,
      /argument 'integer' can not take a string, expected integer/i,
      /argument 'integer' can not take a boolean, expected integer/i,
      /argument 'integer' can not take a float, expected integer/i,
      /argument 'integer' can not take a identifier, expected integer/i,
      /argument 'integer' can not take a reference, expected integer/i,
      /argument 'enum' can not take a integer, expected identifier/i,
      /argument 'enum' can not take value x, expected A, B/i,
      /argument 'related' can not take a integer, expected reference, identifier/i
    ], problems)
  end

  #
  # comment handler
  # 

  def test_comment_handler
    proc_calls = 0
    env, problems = instantiate(%Q(
      #comment
      TestNode text: "node1"
      #comment
      #  multiline
      TestNode text: "node2"
    ), TestMM, :comment_handler => proc {|e,c,env|
      proc_calls += 1
      if e.text == "node1"
        assert_equal "comment", c
      elsif e.text == "node2"
        assert_equal "comment\n  multiline", c
      else
        assert false, "unexpected element in comment handler"
      end
      true
    })
    assert_no_problems(problems)
    assert_equal 2, proc_calls
  end

  def test_comment_handler_comment_not_allowed
    env, problems = instantiate(%Q(
      #comment
      TestNode
    ), TestMM, :comment_handler => proc {|e,c,env|
      false
    })
    assert_problems([/element can not take a comment/], problems)
  end

  #
  # subpackages
  #

  def test_subpackage
    env, problems = instantiate(%q(
      TestNodeSub text: "something" 
    ), TestMMSubpackage)
    assert_no_problems(problems)
    assert_equal "something", env.elements.first.text
  end

  def test_subpackage_no_shortname_opt
    env, problems = instantiate(%q(
      TestNodeSub text: "something" 
    ), TestMMSubpackage, :short_class_names => false)
    assert_problems([/Unknown command 'TestNodeSub'/], problems)
  end

  #
  # values
  # 

  def test_escapes
    env, problems = instantiate(%q(
      TestNode text: "some \" \\\\ \\\\\" text \r xx \n xx \r\n xx \t xx \b xx \f"
    ), TestMM)
    assert_no_problems(problems)
    assert_equal %Q(some " \\ \\" text \r xx \n xx \r\n xx \t xx \b xx \f), env.elements.first.text
  end

  def test_escape_single_backslash
    env, problems = instantiate(%q(
      TestNode text: "a single \\ will be just itself"
    ), TestMM)
    assert_no_problems(problems)
    assert_equal %q(a single \\ will be just itself), env.elements.first.text
  end

  def test_integer
    env, problems = instantiate(%q(
      TestNode integer: 7 
    ), TestMM)
    assert_no_problems(problems)
    assert_equal 7, env.elements.first.integer
  end

  def test_integer_hex
    env, problems = instantiate(%q(
      TestNode text: root {
        TestNode integer: 0x7 
        TestNode integer: 0X7 
        TestNode integer: 0x007 
        TestNode integer: 0x77
        TestNode integer: 0xabCDEF
      }
    ), TestMM)
    assert_no_problems(problems)
    assert_equal [7, 7, 7, 0x77, 0xABCDEF], env.find(:text => "root").first.childs.collect{|c| c.integer}
  end

  def test_float
    env, problems = instantiate(%q(
      TestNode float: 1.23 
    ), TestMM)
    assert_no_problems(problems)
    assert_equal 1.23, env.elements.first.float
  end

  def test_boolean
    env, problems = instantiate(%q(
      TestNode text: root {
        TestNode boolean: true 
        TestNode boolean: false 
      }
    ), TestMM)
    assert_no_problems(problems)
    assert_equal [true, false], env.find(:text => "root").first.childs.collect{|c| c.boolean}
  end

  def test_enum
    env, problems = instantiate(%q(
      TestNode text: root {
        TestNode enum: A 
        TestNode enum: B 
      }
    ), TestMM)
    assert_no_problems(problems)
    assert_equal [:A, :B], env.find(:text => "root").first.childs.collect{|c| c.enum}
  end

  #
  # conflicts with builtins
  # 

  def test_conflict_builtin
    env, problems = instantiate(%q(
      Data notTheBuiltin: "for sure" 
    ), TestMMData)
    assert_no_problems(problems)
    assert_equal "for sure", env.elements.first.notTheBuiltin
  end

  def test_builtin_in_subpackage
    env, problems = instantiate(%q(
      Data notTheBuiltin: "for sure" 
    ), TestMMSubpackage)
    assert_no_problems(problems)
    assert_equal "for sure", env.elements.first.notTheBuiltin
  end

  private

  def instantiate(text, mm, options={})
    env = RGen::Environment.new
    lang = RText::Language.new(mm.ecore, options)
    inst = RText::Instantiator.new(lang)
    problems = []
    inst.instantiate(text, options.merge({:env => env, :problems => problems}))
    return env, problems
  end
  
  def assert_no_problems(problems)
    assert problems.empty?, problems.collect{|p| "#{p.message}, line: #{p.line}"}.join("\n")
  end

  def assert_problems(expected, problems)
    remaining = problems.dup
    probs = []
    expected.each do |e|
      p = problems.find{|p| p.message =~ e}
      probs << "expected problem not present: #{e}" if !p
      remaining.delete(p)
    end
    remaining.each do |p|
      probs << "unexpected problem: #{p.message}, line: #{p.line}"
    end
    assert probs.empty?, probs.join("\n")
  end

  def assert_model_simple(env, *opts)
    raise "unknown options" unless (opts - [:with_nums]).empty?
    root = env.find(:class => TestMM::TestNode, :text => "some text").first
    assert_not_nil root
    assert_equal 2, root.childs.size
    assert_equal [TestMM::TestNode, TestMM::TestNode], root.childs.collect{|c| c.class}
    assert_equal ["child", "child2"], root.childs.text
    if opts.include?(:with_nums)
      assert_equal [1, 2], root.nums
    end
  end

end
	

