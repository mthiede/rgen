<% define 'WSTest', :for => Object do %>
/*
<%ws%>*
<%ws%>*/
<% end %>

<% define 'WSTest2', :for => Object do %>
  <% expand 'SubWithNows' %><%ws%>= 1;
<% end %>

<% define 'SubWithNows', :for => Object do %>
  somevar<%nows%>
<% end %>

<% define 'WSTest3', :for => Object do %>
  <%iinc%>
    /*
    <%ws%>*
    <%ws%>*/
  <%idec%>
<% end %>
