<% define 'Root' do %>
	<% file 'testout.txt' do %>
		Document: <%= title %>
	
		Index:<%iinc%>
		<% for c in chapters %>
			<% nr = (nr || 0); nr += 1 %>
			<% expand 'index/chapter::Root', nr, this, :for => c %>
		<% end %><%idec%>
	
		by <%= author %>
		
		----------------
	
		<% expand 'content/chapter::Root', :foreach => chapters %>
	
	<% end %>
<% end %>

<% def MyNewMethod(arg1, arg2, arg3) %>
<% end %>

