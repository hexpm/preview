defmodule PreviewWeb.SitemapController do
  use PreviewWeb, :controller

  def index(conn, _params) do
    bucket = Application.get_env(:preview, :preview_bucket)
    body = Preview.Storage.get(bucket, "sitemaps/sitemap.xml")
    render_sitemap(conn, body)
  end

  def package(conn, %{"package" => package, "version" => version}) do
    bucket = Application.get_env(:preview, :preview_bucket)
    body = Preview.Storage.get(bucket, "sitemaps/#{package}-#{version}.xml")
    render_sitemap(conn, body)
  end

  defp render_sitemap(conn, body) do
    if body do
      conn
      |> put_resp_content_type("text/xml")
      |> put_resp_header("cache-control", "public, max-age=300")
      |> send_resp(200, body)
    else
      send_resp(conn, 404, "not found")
    end
  end
end
