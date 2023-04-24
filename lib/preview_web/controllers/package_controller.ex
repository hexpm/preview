defmodule PreviewWeb.PackageController do
  use PreviewWeb, :controller

  def raw(conn, %{"package" => package, "filename" => filename} = params) when filename != [] do
    version = params["version"] || Preview.Bucket.get_latest_version(package)
    filename = Path.join(filename)

    if data = Preview.Bucket.get_file(package, version, filename) do
      conn
      |> maybe_put_content_type(Path.extname(filename))
      |> put_resp_header("cache-control", "public, max-age=300")
      |> send_resp(200, data)
    else
      send_resp(conn, 404, "not found")
    end
  end

  @plain_text_exts ~w(.ex .exs .lock .md .txt .erl .hrl .yrl .config .script)

  defp maybe_put_content_type(conn, ext) when ext in @plain_text_exts do
    put_resp_content_type(conn, "text/plain")
  end

  defp maybe_put_content_type(conn, _ext) do
    conn
  end
end
