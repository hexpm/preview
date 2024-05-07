defmodule PreviewWeb.PreviewLive do
  use PreviewWeb, :live_view

  alias Makeup.Lexers.{EExLexer, ElixirLexer, ErlangLexer}

  require Logger

  @max_file_size 2 * 1000 * 1000
  @makeup_timeout 1000

  defmodule Exception do
    defexception [:plug_status]

    def message(%{plug_status: status}) do
      "plug status: #{status}"
    end
  end

  @impl true
  def mount(params, _session, socket) do
    package = params["package"]
    version = params["version"] || Preview.Bucket.get_latest_version(package)

    if all_files = Preview.Bucket.get_file_list(package, version) do
      all_files = Enum.sort(all_files)

      filename =
        if params["filename"] && params["filename"] != [] do
          Path.join(params["filename"])
        else
          default_file(all_files)
        end

      file_contents = file_contents_or_default(package, version, filename)

      {:ok,
       assign(socket,
         package: package,
         version: version,
         all_files: all_files,
         filename: filename,
         file_contents: file_contents,
         makeup_file_contents: makeup_file_contents(package, version, filename, file_contents),
         selected_line: 0,
         page_title: filename,
         meta_description: meta_description(package, version, filename),
         canonical: canonical_url(package, filename)
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
        makeup_file_contents: makeup_file_contents(package, version, filename, file_contents),
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

  defp makeup_file_contents(package, version, filename, file_contents) do
    case makeup_lexer(filename) do
      {:ok, lexer} ->
        task =
          Task.Supervisor.async_nolink(Preview.Tasks, fn ->
            Makeup.highlight(file_contents, lexer: lexer)
          end)

        case Task.yield(task, @makeup_timeout) || Task.shutdown(task, @makeup_timeout) do
          {:ok, makeup} ->
            makeup

          {:exit, reason} ->
            name = "#{package} #{version} #{filename}"
            reason = inspect(reason)
            Logger.warning("Failed to makeup #{name}, reason: #{reason}")

            default_content(file_contents)

          nil ->
            name = "#{package} #{version} #{filename}"
            Logger.warning("Failed to makeup #{name}, timeout")
            default_content(file_contents)
        end

      :error ->
        default_content(file_contents)
    end
  end

  defp default_content(file_contents) do
    content_tag(:pre, content_tag(:code, file_contents), class: "highlight")
  end

  def default_file(all_files) do
    default_files =
      Enum.filter(all_files, fn file ->
        case default_file_priority(file) do
          {:ok, _} -> true
          :error -> false
        end
      end)

    if default_files == [] do
      hd(all_files)
    else
      default_files
      |> Enum.sort_by(&default_file_priority/1)
      |> List.first()
    end
  end

  @default_file_priority ["mix.exs", "rebar.config", "Makefile"] |> Enum.with_index(2) |> Map.new()

  defp default_file_priority(file) do
    if file |> String.downcase() |> String.starts_with?("readme") do
      {:ok, 1}
    else
      Map.fetch(@default_file_priority, file)
    end
  end

  defp file_contents_or_default(package, version, filename) do
    file_contents = Preview.Bucket.get_file(package, version, filename)

    cond do
      !file_contents ->
        raise Exception, plug_status: 404

      not String.valid?(file_contents) ->
        "Contents for binary files are not shown."

      byte_size(file_contents) > @max_file_size ->
        "File is too large to be displayed #{div(byte_size(file_contents), 1_000_000)}MB."

      true ->
        file_contents
    end
  end

  defp makeup_lexer(filename) do
    cond do
      Path.extname(filename) in [".ex", ".exs"] -> {:ok, ElixirLexer}
      Path.extname(filename) in [".eex", ".heex"] -> {:ok, EExLexer}
      Path.extname(filename) in [".erl", ".hrl", ".escript"] -> {:ok, ErlangLexer}
      filename in ["rebar.config", "rebar.config.script"] -> {:ok, ErlangLexer}
      String.ends_with?(filename, ".app.src") -> {:ok, ErlangLexer}
      true -> :error
    end
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
