<% define 'Mixed', :for => Object do %>
  <% file "line_endings_mixed.txt" do %>
    first line (unix) |
    second line (windows) |
  <% end %>
<% end %>
