<% define 'Test', :for => Object do %>
  <%iinc%>
	<% expand 'Sub' %>
  <%idec%>
<% end %>

<% define 'Sub', :for => Object do %>
	Sub
	<%# white space after the following end tag but no NL %>
	<%# the bug was triggered when the @output of template loading %>
	<%# was non empty and not terminated by a newline; %>
	<%# without the space after end, the newline above this %>
	<%# define block would be the last character %>
<% end %> 