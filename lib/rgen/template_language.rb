# RGen Framework
# (c) Martin Thiede, 2006

require 'rgen/template_language/directory_template_container'
require 'rgen/template_language/template_container'

module RGen

# The RGen template language has been designed to build complex generators.
# It is very similar to the EXPAND language of the Java based
# OpenArchitectureWare framework.
# 
# =Templates
# 
# The basic idea is to allow "templates" not only being template files
# but smaller parts. Those parts can be expanded from other parts very 
# much like Ruby methods are called from other methods.
# Thus the term "template" refers to such a part within a "template file".
# 
# Template files used by the RGen template language should have a 
# filename with the postfix ".tpl". Those files can reside within (nested)
# template file directories.
# 
# As an example a template directory could look like the following:
# 
# 	templates/root.tpl
# 	templates/dbaccess/dbaccess.tpl
# 	templates/dbaccess/schema.tpl
# 	templates/headers/generic_headers.tpl
# 	templates/headers/specific/component.tpl
# 
# A template is always called for a <i>context object</i>. The context object
# serves as the receiver of methods called within the template. Details are given
# below.
# 
# 
# =Defining Templates
# 
# One or more templates can be defined in a template file using the +define+
# keyword as in the following example:
# 
# 	<% define 'GenerateDBAdapter', :for => DBDescription do |dbtype| %>
# 		Content to be generated; use ERB syntax here
# 	<% end %>
# 
# The template definition takes three kinds of parameters:
# 1. The name of the template within the template file as a String or Symbol
# 2. An optional class object describing the class of context objects for which
#    this template is valid.
# 3. An arbitrary number of template parameters
# See RGen::TemplateLanguage::TemplateContainer for details about the syntax of +define+.
# 
# Within a template, regular ERB syntax can be used. This is
# * <code><%</code> and <code>%></code> are used to embed Ruby code
# * <code><%=</code> and <code>%></code> are used to embed Ruby expressions with
#   the expression result being written to the template output
# * <code><%#</code> and <code>%></code> are used for comments
# All content not within these tags is written to the template output verbatim.
# See below for details about output files and output formatting.
# 
# All methods which are called from within the template are sent to the context
# object.
#
# 
# =Expanding Templates
# 
# Templates are normally expanded from within other templates. The only
# exception is the root template, which is expanded from the surrounding code.
# 
# Template names can be specified in the following ways:
# * Non qualified name: use the template with the given name in the current template file
# * Relative qualified name: use the template within the template file specified by the relative path
# * Absolute qualified name: use the template within the template file specified by the absolute path
# 
# The +expand+ keyword is used to expand templates. 
# 
# Here are some examples:
# 
# 	<% expand 'GenerateDBAdapter', dbtype, :for => dbDesc %>
# 
# <i>Non qualified</i>. Must be called within the file where 'GenerateDBAdapter' is defined.
# There is one template parameter passed in via variable +dbtype+.
# The context object is provided in variable +dbDesc+.
#  
# 	<% expand 'dbaccess::ExampleSQL' %>
# 
# <i>Qualified with filename</i>. Must be called from a file in the same directory as 'dbaccess.tpl'
# There are no parameters. The current context object will be used as the context 
# object for this template expansion.
# 
# 	<% expand '../headers/generic_headers::CHeader', :foreach => modules %>
# 
# <i>Relatively qualified</i>. Must be called from a location from which the file
# 'generic_headers.tpl' is accessible via the relative path '../headers'.
# The template is expanded for each module in +modules+ (which has to be an Array).
# Each element of +modules+ will be the context object in turn.
# 
# 	<% expand '/headers/generic_headers::CHeader', :foreach => modules %>
# 
# Absolutely qualified: The same behaviour as before but with an absolute path from
# the template directory root (which in this example is 'templates', see above)
# 
# 
# =Output Files and Formatting
# 
# Normally the generated content is to be written into one or more output files.
# The RGen template language facilitates this by means of the +file+ keyword.
# 
# When the +file+ keyword is used to define a block, all output generated
# from template code within this block will be written to the specified file.
# This includes output generated from template expansions.
# Thus all output from templates expanded within this block is written to
# the same file as long as those templates do not use the +file+ keyword to 
# define a new file context.
# 
# Here is an example:
# 
# 	<% file 'dbadapter/'+adapter.name+'.c' do %>
# 		all content within this block will be written to the specified file
# 	<% end %>
# 
# Note that the filename itself can be calculated dynamically by an arbitrary
# Ruby expression.
# 
# The absolute position where the output file is created depends on the output
# root directory passed to DirectoryTemplateContainer as described below.
# 
# =Setting up the Generator
# 
# Setting up the generator consists of 3 steps:
# * Instantiate DirectoryTemplateContainer passing the metamodel and the output 
#   directory to the constructor.
# * Load the templates into the template container
# * Expand the root template to start generation
# 
# Here is an example:
#
# 	module MyMM
# 		# metaclasses are defined here, e.g. using RGen::MetamodelBuilder
# 	end
# 
# 	OUTPUT_DIR = File.dirname(__FILE__)+"/output"
# 	TEMPLATES_DIR = File.dirname(__FILE__)+"/templates"
# 
# 	tc = RGen::TemplateLanguage::DirectoryTemplateContainer.new(MyMM, OUTPUT_DIR)
# 	tc.load(TEMPLATES_DIR)
# 	# testModel should hold an instance of the metamodel class expected by the root template
# 	# the following line starts generation
# 	tc.expand('root::Root', :for => testModel, :indent => 1)
# 
# The metamodel is the Ruby module which contains the metaclasses.
# This information is required for the template container in order to resolve the
# metamodel classes used within the template file. 
# 
# The output path is prepended to the relative paths provided to the +file+ 
# definitions in the template files.
#
# The template directory should contain template files as described above.
#
# Finally the generation process is started by calling +expand+ in the same way as it
# is used from within templates.
# 
# Also see the unit tests for more examples.
# 
module TemplateLanguage

end

end