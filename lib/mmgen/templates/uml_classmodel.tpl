
<% define 'GenerateClassModel', :for => UMLPackage do |filename, modules| %>
	<% file filename do %>
		require 'rgen/metamodel_builder'
		
		<% expand 'GeneratePackage', modules %>
		<%nl%>
		<% expand 'GenerateAssocs' %>
	<% end %>
<% end %>
		
<% define 'GeneratePackage', :for => UMLPackage do |modules| %>
	module <%= moduleName %><% iinc %>
		<% for c in sortedClasses %><%nl%>
			<% expand 'ModuleHeader', modules, :for => c %><%iinc%>
				<% (c.superclasses.name & modules).each do |n| %>
					include <%= n %>
				<% end %>
				<% if modules.include?(c.className) %>
					extend RGen::MetamodelBuilder::BuilderExtensions
				<% end %>
				has_one 'name', String
				<% for a in c.attributes %>
					has_one '<%= a.name %>', <%= a.RubyType %>
				<% end %><%idec%>
			end
		<% end %><%nl%>
		<% for p in subpackages %>
			<%nl%><% expand 'GeneratePackage', modules, :for => p %>
		<% end %><%idec%>
	end
<% end %>

<% define 'GenerateAssocs', :for => UMLPackage do %>
	<% for a in allClasses.assocEnds>>:assoc %>
		<% if a.endA.one? %>
			<% if a.endB.one? %>
				<%= a.endA.clazz.qualifiedName(this) %>.one_to_one '<%= a.endB.MName %>', <%= a.endB.clazz.qualifiedName(this) %>, '<%= a.endA.MName %>'
			<% elsif a.endB.many? %>
				<%= a.endA.clazz.qualifiedName(this) %>.one_to_many '<%= a.endB.MName %>', <%= a.endB.clazz.qualifiedName(this) %>, '<%= a.endA.MName %>'
			<% end %>
		<% elsif a.endA.many? %>
			<% if a.endB.one? %>
				<%= a.endB.clazz.qualifiedName(this) %>.one_to_many '<%= a.endA.MName %>', <%= a.endA.clazz.qualifiedName(this) %>, '<%= a.endB.MName %>'
			<% elsif a.endB.many? %>
				<%= a.endB.clazz.qualifiedName(this) %>.many_to_many '<%= a.endA.MName %>', <%= a.endA.clazz.qualifiedName(this) %>, '<%= a.endB.MName %>'
			<% end %>
		<% end %>
	<% end %>
<% end %>

<% define 'ModuleHeader' do |modules| %>
	<% if modules.include?(name) %>
		module <%= className %>
	<% else %>
		class <%= className %> < <% nows %>
		<% if rsc=RubySuperclass(modules) %><% nows %>
			<%= rsc.className %>
		<% else %><% nows %>
			RGen::MetamodelBuilder::MMBase
		<% end %>
	<% end %>
<% end %>