defmodule PreviewWeb.PreviewLive do
  use PreviewWeb, :live_view
  require Logger

  @impl true
  def mount(params, _session, socket) do
    case maybe_cached_contents(params["package"], params["version"]) do
      {:ok, contents} ->
        {filename, file_contents} = contents |> Enum.to_list() |> List.first()

        {:ok,
         assign(socket,
           package: params["package"],
           version: params["version"],
           contents: contents,
           filename: filename,
           file_contents: file_contents
         )}

      error ->
        assign(socket, error: inspect(error))
    end
  end

  @impl true
  # captures when user selects a file
  def handle_event(
        "select_file",
        %{"file_chooser" => filename},
        %{assigns: %{contents: contents, package: package, version: version}} = socket
      ) do
    {filename, file_contents} =
      Enum.find(contents, fn {name, _contents} ->
        to_charlist(filename) == name
      end)

    {:noreply,
     assign(socket,
       package: package,
       version: version,
       contents: contents,
       filename: filename,
       file_contents: file_contents
     )}
  end

  def selected(x, x), do: "selected=selected"

  def selected(str, io) do
    if to_charlist(io) == str, do: "selected=selected"
  end

  defp maybe_cached_contents(pkg, ver) do
    case Preview.Storage.get(pkg, ver) do
      {:ok, contents} ->
        Logger.debug("cache hit for #{pkg}/#{ver}")
        {:ok, contents}

      {:error, :not_found} ->
        Logger.debug("cache miss for #{pkg}/#{ver}")
        do_preview(pkg, ver)
    end
  end

  defp do_preview(pkg, ver) do
    case Preview.Hex.preview(pkg, ver) do
      {:ok, stream} ->
        {:ok, stream}

      :error ->
        "Server error"
    end
  end

  defp cache_preview(package, version, stream) do
    Task.Supervisor.start_child(Preview.Tasks, fn ->
      Preview.Storage.put(package, version, stream)
    end)
  end
end
