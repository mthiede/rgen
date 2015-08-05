<% define 'Test', :for => Object do %>
  <%iinc%>
	Start <% expand 'Sub' %><%nows%>
  <%idec%>
<% end %>

<% define 'Sub', :for => Object do %>
  <%# here we have the noIndentNextLine flag set %>
  <% expand 'Sub2' %>
  Sub
<% end %>

<% define 'Sub2', :for => Object do %>
  <%# here we reset the noIndentNextLine flag %>
  Sub2
<% end %>
