$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/environment'
require 'rgen/metamodel_builder'
require 'rgen/instantiator/text_instantiator'

class TextInstantiatorTest < Test::Unit::TestCase

  module TestMM
    extend RGen::MetamodelBuilder::ModuleExtension
    class TestNode < RGen::MetamodelBuilder::MMBase
      has_attr 'text', String
      has_attr 'integer', Integer
      has_many_attr 'nums', Integer
      has_attr 'float', Float
      has_one 'related', TestNode
      has_many 'others', TestNode
      contains_many 'childs', TestNode, 'parent'
    end
  end

  module TestMMLineno
    extend RGen::MetamodelBuilder::ModuleExtension
    class TestNode < RGen::MetamodelBuilder::MMBase
      has_attr 'text', String
      has_attr 'lineno', Integer
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

  def test_references
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
    ), TestMM)
    assert_no_problems(problems)
    assert_equal [ 
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
    ], env.find(:text => "root").first.childs.collect{|c| c.related.targetIdentifier}
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

  def test_unexpected_unlabled_argument
    env, problems = instantiate(%Q(
      TestNode "more text"
    ), TestMM)
    assert_problems([/unexpected unlabled argument, 0 unlabled arguments expected/i], problems)
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

  def test_comment_handler
    proc_calls = 0
    env, problems = instantiate(%Q(
      #comment
      TestNode text: "node1"
      #comment
      #  multiline
      TestNode text: "node2"
    ), TestMM, :comment_handler => proc {|e,c|
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
    ), TestMM, :comment_handler => proc {|e,c|
      false
    })
    assert_problems([/element can not take a comment/], problems)
  end

  def test_line_number_setter
    env, problems = instantiate(%q(
      TestNode text: "node1" {
        TestNode text: "node2"

        #some comment
        TestNode text: "node3"
      }
      TestNode text: "node4"
    ), TestMMLineno, :line_number_setter => "lineno=")
    assert_no_problems(problems)
    assert_equal 2, env.find(:text => "node1").first.lineno
    assert_equal 3, env.find(:text => "node2").first.lineno
    assert_equal 6, env.find(:text => "node3").first.lineno
    assert_equal 8, env.find(:text => "node4").first.lineno
  end

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

  def test_float
    env, problems = instantiate(%q(
      TestNode float: 1.23 
    ), TestMM)
    assert_no_problems(problems)
    assert_equal 1.23, env.elements.first.float
  end

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

  def instantiate(text, mm, options={})
    env = RGen::Environment.new
    inst = RGen::Instantiator::TextInstantiator.new(env, mm, options)
    problems = []
    inst.instantiate(text, problems)
    return env, problems
  end
  
  def assert_no_problems(problems)
    assert problems.empty?, problems.collect{|p| "#{p[0]}, line: #{p[1]}"}
  end

  def assert_problems(expected, problems)
    remaining = problems.dup
    probs = []
    expected.each do |e|
      p = problems.find{|p| p[0] =~ e}
      probs << "expected problem not present: #{e}" if !p
      remaining.delete(p)
    end
    remaining.each do |p|
      probs << "unexpected problem: #{p[0]}, line: #{p[1]}"
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
	

