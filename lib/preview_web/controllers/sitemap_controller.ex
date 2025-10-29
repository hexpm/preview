defmodule PreviewWeb.SitemapController do
  use PreviewWeb, :controller
  plug :put_format, "xml"

  def index(conn, _params) do
    bucket = Application.get_env(:preview, :preview_bucket)
    body = Preview.Storage.get(bucket, "sitemaps/sitemap.xml")
    render_sitemap(conn, body)
  end

  def package(conn, %{"package" => package}) do
    bucket = Application.get_env(:preview, :preview_bucket)
    body = Preview.Storage.get(bucket, "sitemaps/#{package}.xml")
    render_sitemap(conn, body)
  end

  defp render_sitemap(conn, body) do
    if body do
      conn
      |> put_resp_content_type("text/xml")
      |> put_resp_header("cache-control", "public, max-age=300")
      |> send_resp(200, body)
    else
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(404, "not found")
    end
  end
end
