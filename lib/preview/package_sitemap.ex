defmodule Preview.PackageSitemap do
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
      <loc><%= Routes.preview_url(PreviewWeb.Endpoint, :index, name, version) <> "/show/" <> file %></loc>
      <lastmod><%= format_datetime updated_at %></lastmod>
      <changefreq>daily</changefreq>
      <priority>0.8</priority>
    </url>
  <% end %>
  </urlset>
  """

  EEx.function_from_string(:def, :render, template, [:name, :version, :files, :updated_at])

  defp format_datetime(datetime) do
    datetime |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end
end
