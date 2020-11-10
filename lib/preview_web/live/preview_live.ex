defmodule PreviewWeb.PreviewLive do
  use PreviewWeb, :live_view
  require Logger

  # TODO: Handle binary files when they fail to JSON encode

  @impl true
  def mount(params, _session, socket) do
    if all_files = Preview.Bucket.get_file_list(params["package"], params["version"]) do
      first_file = hd(all_files)
      file_contents = Preview.Bucket.get_file(params["package"], params["version"], first_file)

      {:ok,
       assign(socket,
         package: params["package"],
         version: params["version"],
         all_files: all_files,
         filename: first_file,
         file_contents: file_contents
       )}
    else
      assign(socket, error: "TODO")
    end
  end

  @impl true
  # captures when user selects a file
  def handle_event(
        "select_file",
        %{"file_chooser" => filename},
        %{assigns: %{all_files: all_files, package: package, version: version}} = socket
      ) do
    file_contents = Preview.Bucket.get_file(package, version, filename)

    {:noreply,
     assign(socket,
       package: package,
       version: version,
       all_files: all_files,
       filename: filename,
       file_contents: file_contents
     )}
  end

  def selected(x, x), do: "selected=selected"

  def selected(str, io) do
    if to_charlist(str) == io, do: "selected=selected"
  end

  def print_file_contents(file_contents) do
    file_contents
    |> Phoenix.HTML.Format.text_to_html()
    |> Phoenix.HTML.safe_to_string()
    |> String.replace(" ", "&nbsp;")
  end
end
