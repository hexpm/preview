defmodule PreviewWeb.PreviewLive do
  use PreviewWeb, :live_view

  @impl true
  def mount(%{"version" => "latest"} = params, session, socket) do
    params = %{params | "version" => "2.0.0"}
    mount(params, session, socket)
  end

  def mount(params, _session, socket) do
    if all_files = Preview.Bucket.get_file_list(params["package"], params["version"]) do
      filename =
        if params["filename"] do
          Path.join(params["filename"])
        else
          default_file(all_files)
        end

      file_contents = file_contents_or_default(params["package"], params["version"], filename)

      {:ok,
       assign(socket,
         package: params["package"],
         version: params["version"],
         all_files: all_files,
         filename: filename,
         file_contents: file_contents,
         selected_line: 0,
         page_title: filename,
         meta_description: meta_description(params["package"], params["version"], filename)
       )}
    else
      {:ok, assign(socket, error: "TODO")}
    end
  end

  @impl true
  def handle_params(_params, uri, socket) do
    %{fragment: hash} = URI.parse(uri)
    socket = maybe_assign_selected_line(hash, socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("highlight_line", %{"line-number" => line_number}, socket) do
    {line_number, _} = Integer.parse(line_number)
    socket = assign(socket, :selected_line, line_number)

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
        file_contents: file_contents,
        page_title: filename,
        meta_description: meta_description(package, version, filename)
      )

    {:noreply,
     push_patch(socket,
       to: Routes.preview_path(socket, :index, package, version) <> "/show/#{filename}",
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
      content_tag(:pre, content_tag(:code, file_contents), class: "highlight")
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

  defp maybe_assign_selected_line(<<"L", number::binary>>, socket) do
    {line_number, _} = Integer.parse(number)
    assign(socket, :selected_line, line_number)
  end

  defp maybe_assign_selected_line(_, socket), do: assign(socket, :selected_line, nil)

  defp meta_description(package, version, filename) do
    if language = language(Path.extname(filename)) do
      "#{filename} from #{package} #{version} written in #{language}"
    end
  end

  defp language(ext) when ext in ~w(.ex .exs), do: "the Elixir programming language"
  defp language(ext) when ext in ~w(.erl .hrl .escript), do: "the Erlang programming language"
  defp language(".md"), do: "Markdown"
  defp language(_), do: nil
end
