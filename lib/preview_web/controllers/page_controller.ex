defmodule PreviewWeb.PageController do
  use PreviewWeb, :controller

  def preview(conn, %{"package" => package, "version" => version}) do
    {:ok, tarball} = Preview.Hex.get_tarball(package, version)
    {:ok, %{contents: contents}} = :hex_tarball.unpack(tarball, :memory)

    directory_tree = directory_tree(contents)

    conn
    |> assign(:contents, contents)
    |> render()
  end

  def directory_tree(contents) do
    Enum.map(contents, fn {dir_or_file, _contents} ->
      Path.split(dir_or_file)
    end)
  end
end
