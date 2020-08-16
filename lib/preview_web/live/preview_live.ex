defmodule PreviewWeb.PreviewLive do
  use PreviewWeb, :live_view
  require Logger

  @unsafe_files [".DS_Store"]

  @impl true
  def mount(params, _session, socket) do
    case maybe_cached_contents(params["package"], params["version"]) do
      {:ok, list_of_files} ->
        list_of_files = normalize_file_list(list_of_files)

        file_contents =
          case maybe_cached_contents(
                 params["package"],
                 params["version"],
                 List.first(list_of_files)
               ) do
            {:ok, list} when is_list(list) -> list |> List.first() |> elem(1)
            {:ok, file_contents} -> file_contents
          end

        {:ok,
         assign(socket,
           package: params["package"],
           version: params["version"],
           contents: list_of_files,
           filename: List.first(list_of_files),
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
    {:ok, file_contents} = maybe_cached_contents(package, version, filename)

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
    if to_charlist(str) == io, do: "selected=selected"
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

  defp maybe_cached_contents(pkg, ver, {filename, _contents}) do
    maybe_cached_contents(pkg, ver, filename)
  end

  defp maybe_cached_contents(pkg, ver, file) do
    if String.ends_with?("#{file}", @unsafe_files) do
      {:ok, "This file cannot be safely parsed."}
    else
      case Preview.Storage.get_file(pkg, ver, file) do
        {:ok, contents} ->
          Logger.debug("cache hit for #{pkg}/#{ver}/#{file}")
          {:ok, contents}

        {:error, :not_found} ->
          Logger.debug("cache miss for #{pkg}/#{ver}/#{file}")
          do_preview(pkg, ver)
      end
    end
  end

  defp do_preview(pkg, ver) do
    case Preview.Hex.preview(pkg, ver) do
      {:ok, contents} ->
        cache_preview(pkg, ver, contents)
        {:ok, contents}

      :error ->
        "Server error"
    end
  end

  defp cache_preview(package, version, contents) do
    Task.Supervisor.start_child(Preview.Tasks, fn ->
      # this should store each file in the contents separately
      Preview.Storage.put(package, version, contents)
    end)
  end

  def print_contents({_filename, file_contents}), do: print_contents(file_contents)

  def print_contents(file_contents) do
    file_contents
    |> Phoenix.HTML.Format.text_to_html()
    |> Phoenix.HTML.safe_to_string()
    |> String.replace(" ", "&nbsp;")
  end

  def normalize_file_list([{_f, _c} | _rest] = list_with_contents) do
    Enum.map(list_with_contents, &elem(&1, 0))
  end

  def normalize_file_list(list) when is_list(list), do: list
end
