defmodule PreviewWeb.PreviewLive do
  use PreviewWeb, :live_view
  require Logger

  # TODO: Handle binary files when they fail to JSON encode

  @impl true
  def mount(params, _session, socket) do
    if all_files = Preview.Bucket.get_file_list(params["package"], params["version"]) do
      filename = if params["filename"], do: URI.decode(params["filename"]), else: hd(all_files)
      file_contents = Preview.Bucket.get_file(params["package"], params["version"], filename)

      if String.valid?(file_contents),
        do: file_contents,
        else: "Contents for binary files are not shown."

      {:ok,
       assign(socket,
         package: params["package"],
         version: params["version"],
         all_files: all_files,
         filename: filename,
         file_contents: file_contents
       )}
    else
      {:ok, assign(socket, error: "TODO")}
    end
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket}
  end

  @impl true
  # captures when user selects a file
  def handle_event(
        "select_file",
        %{"file_chooser" => filename},
        %{assigns: %{all_files: all_files, package: package, version: version}} = socket
      ) do
    file_contents = Preview.Bucket.get_file(package, version, filename)

    socket =
      assign(socket,
        package: package,
        version: version,
        all_files: all_files,
        filename: filename,
        file_contents: file_contents
      )

    {:noreply,
     push_patch(socket,
       to: Routes.preview_path(socket, :index, package, version, filename),
       replace: true
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
