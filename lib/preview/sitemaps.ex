defmodule Preview.Sitemaps do
  require EEx

  alias PreviewWeb.Router.Helpers, as: Routes

  template = ~S"""
  <?xml version="1.0" encoding="utf-8"?>
  <urlset
      xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
  <%= for file <- files do %>
    <url>
      <loc><%= Routes.preview_url(PreviewWeb.Endpoint, :latest, name) <> "/show/" <> file %></loc>
      <lastmod><%= format_datetime updated_at %></lastmod>
      <changefreq>daily</changefreq>
      <priority>0.8</priority>
    </url>
  <% end %>
  </urlset>
  """

  EEx.function_from_string(:def, :render_package, template, [:name, :files, :updated_at])

  template = ~S"""
  <?xml version="1.0" encoding="utf-8"?>
  <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <%= for package <- packages do %>
    <sitemap>
      <loc><%= Routes.sitemap_url(PreviewWeb.Endpoint, :package, package.name) %></loc>
      <lastmod><%= format_datetime package.updated_at %></lastmod>
    </sitemap>
  <% end %>
  </sitemapindex>
  """

  EEx.function_from_string(:def, :render_index, template, [:packages])

  defp format_datetime(%DateTime{} = datetime) do
    datetime |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end

  defp format_datetime(%{seconds: seconds}) do
    seconds
    |> DateTime.from_unix!()
    |> format_datetime()
  end
end
