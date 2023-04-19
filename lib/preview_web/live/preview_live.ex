defmodule PreviewWeb.PreviewLive do
  use PreviewWeb, :live_view

  @max_file_size 2 * 1000 * 1000

  defmodule Exception do
    defexception [:plug_status]

    def message(%{plug_status: status}) do
      "plug status: #{status}"
    end
  end

  @impl true
  def mount(params, _session, socket) do
    version = params["version"] || Preview.Bucket.get_latest_version(params["package"])

    if all_files = Preview.Bucket.get_file_list(params["package"], version) do
      filename =
        if params["filename"] && params["filename"] != [] do
          Path.join(params["filename"])
        else
          default_file(all_files)
        end

      file_contents = file_contents_or_default(params["package"], version, filename)

      {:ok,
       assign(socket,
         package: params["package"],
         version: version,
         all_files: all_files,
         filename: filename,
         file_contents: file_contents,
         selected_line: 0,
         page_title: filename,
         meta_description: meta_description(params["package"], version, filename),
         canonical: canonical_url(params["package"], filename)
       )}
    else
      raise Exception, plug_status: 404
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
        meta_description: meta_description(package, version, filename),
        canonical: canonical_url(package, filename)
      )

    {:noreply,
     push_patch(socket,
       to: Routes.preview_path(socket, :index, package, version) <> "/show/#{filename}",
       replace: true
     )}
  end

  def selected(x, x), do: [selected: "selected"]

  def selected(str, io) do
    if to_charlist(str) == io, do: [selected: "selected"], else: []
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

    cond do
      !file_contents ->
        "No file with this name."

      not String.valid?(file_contents) ->
        "Contents for binary files are not shown."

      byte_size(file_contents) > @max_file_size  ->
        "File is too large to be displayed #{div(byte_size(file_contents), 1_000_000)}MB."

      true ->
        file_contents
    end
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

  defp canonical_url(package, filename) do
    PreviewWeb.Router.Helpers.preview_url(PreviewWeb.Endpoint, :latest, package) <>
      "/show/" <> filename
  end
end
