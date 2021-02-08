defmodule PreviewWeb.PreviewLive do
  use PreviewWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    if all_files = Preview.Bucket.get_file_list(params["package"], params["version"]) do
      filename =
        if params["filename"], do: URI.decode(params["filename"]), else: default_file(all_files)

      file_contents = file_contents_or_default(params["package"], params["version"], filename)

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
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  # captures when user selects a file
  def handle_event(
        "select_file",
        %{"file_chooser" => filename},
        %{assigns: %{all_files: all_files, package: package, version: version}} = socket
      ) do
    file_contents = file_contents_or_default(package, version, filename)

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

  def print_file_contents(file_contents, filename) do
    if makeup_supported?(filename) do
     Makeup.highlight(file_contents)
    else
      file_contents
      |> Phoenix.HTML.Format.text_to_html()
      |> Phoenix.HTML.safe_to_string()
      |> String.replace(" ", "&nbsp;")
    end
  end

  def default_file(all_files) do
    Enum.find(all_files, &(&1 |> String.downcase() |> String.starts_with?("readme"))) ||
      Enum.find(all_files, &(&1 == "mix.exs")) ||
      Enum.find(all_files, &(&1 == "rebar.config")) ||
      Enum.find(all_files, &(&1 == "Makefile")) ||
      hd(all_files)
  end

  defp file_contents_or_default(package, version, filename) do
    file_contents = Preview.Bucket.get_file(package, version, filename)

    if String.valid?(file_contents),
      do: file_contents,
      else: "Contents for binary files are not shown."
  end

  defp makeup_supported?(filename) do
    Path.extname(filename) in [".ex", ".exs", ".erl", ".hrl", ".escript"] ||
      filename in ["rebar.config", "rebar.config.script"] ||
      String.ends_with?(filename, ".app.src")
  end
end
